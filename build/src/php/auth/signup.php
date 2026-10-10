<?php 

// signup.php — user registration, company code validation, verification email

// --- Initialization ---

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/rate_limit_helpers.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/mail/MailService.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/email_verification_helpers.php';
    session_start();

    $fname = $_POST["name"];
    $lname = $_POST["surname"];
    $code = $_POST["code"];
    $role = $_POST["role"];
    $email = $_POST["email"];
    $username = $_POST["username"];
    $password = $_POST["password"];
    $ip = getClientIp();

    enforceRateLimitOrExit('signup', $ip, $username);

   
// --- validation ---

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo '<script type="text/javascript">';
        echo 'alert("Wrong email address.");';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }

    if (empty($fname) || empty($lname) || empty($username) || empty($password) ||
        strlen($password) < 8 || !preg_match('/(?=.*[A-Za-z])(?=.*\d)/', $password)){
            echo '<script type="text/javascript">';
            echo 'alert("Password must be at least 8 characters with one letter and one number.");';
            echo 'window.history.back()';
            echo '</script>';
            exit();
    }
    
    try {
        $prpUcheck = $conn -> prepare("SELECT COUNT(username) FROM user WHERE username = ?");
        $prpUcheck ->bind_param("s",$username);
        if(!$prpUcheck -> execute()){
            throw new Exception("An error occured.");
        }
        $prpUcheck->bind_result($countU);
        $prpUcheck -> fetch();
        $prpUcheck->close();
        
        $prpEcheck = $conn -> prepare("SELECT COUNT(email) FROM user WHERE email = ?");
        $prpEcheck ->bind_param("s",$email);
        if(!$prpEcheck -> execute()){
            throw new Exception("An error occured.");
        }
        $prpEcheck->bind_result($countE);
        $prpEcheck->fetch();
        $prpEcheck->close();


        $codeQuery = "SELECT 
                    id,
                    CASE 
                        WHEN codeManager = ? THEN 'manager'
                        WHEN codeEmployee = ? THEN 'employee'
                    END as matched_position
                    FROM company 
                    WHERE codeManager = ? OR codeEmployee = ?";
        $prpCcheck = $conn -> prepare("$codeQuery");



        $prpCcheck->bind_param("ssss",$code,$code,$code,$code);

        if(!$prpCcheck -> execute()){
            throw new Exception("An error occured.");
        }

        $infoFromCode = $prpCcheck->get_result();
        $prpCcheck->close();

        $signup = true;
        $uTrue = $eTrue = $cTrue =  false; // username/email/code availability flags

        if ($countU == 0 ){
            $uTrue =  true;
        }else{
            $signup = false;
        }
        
        
        if($countE == 0){
            $eTrue =  true;
        }else{
            $signup = false;
        }
        
        
        if($infoFromCode->num_rows > 0) {
            $cTrue = true;
            $row = $infoFromCode->fetch_assoc();
            if ($row === false) {
                throw new Exception(1);
            }
            $position = $row["matched_position"]; // manager / employee from company code
            $companyID = $row["id"];
            $infoFromCode->close();
        }else{
            $signup = false;
        }
        

// --- signup ---

        if ($signup == true) {
                $conn->begin_transaction();
                $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

                $prpIns = $conn->prepare("INSERT INTO user (Name,Surname,username,password,email,companyID,emailVerified) VALUES (?,?,?,?,?,?,0)");
                $prpIns->bind_param("sssssi",$fname,$lname,$username, $hashedPassword, $email, $companyID);
                if(!$prpIns->execute()){
                    throw new Exception("An error occured.");
                }
                $userId = (int) $conn->insert_id;
                $prpIns->close();

                if($position == "manager"){
                    $prpIns = $conn->prepare("INSERT INTO manager (id,role) VALUES (?, ?)");
                    $prpIns->bind_param("is", $userId, $role);
                    if(!$prpIns->execute()){
                        throw new Exception("An error occured.");
                    }
                    $prpIns->close();
                }else{
                    $prpIns = $conn->prepare("INSERT INTO employee (id,role) VALUES (?, ?)");
                    $prpIns->bind_param("is", $userId, $role);
                    if(!$prpIns->execute()){
                        throw new Exception("An error occured.");
                    }
                    $prpIns->close();
                }

                $token = createVerificationToken($conn, $userId, null);
                $conn->commit();
                clearRateLimit('signup', $ip, $username);

                try {
                    MailService::sendVerificationEmail($email, $token, $username);
                    $successMessage = 'Account created! Check your email and verify your account before you can log in.';
                } catch (Throwable $mailError) {
                    logAppError($mailError);
                    $successMessage = 'Account created, but the verification email could not be sent. Contact support.';
                }

                echo '<script type="text/javascript">';
                echo 'alert(' . json_encode($successMessage) . ');';
                echo 'window.location.href = "/html/auth/login.html";';
                echo '</script>';
                exit();
        
        }else{
            recordRateLimitFailure('signup', $ip, $username);
            if(!$eTrue){
                echo '<script type="text/javascript">';
                echo 'alert("Email is taken.");';
                echo 'window.history.back()';
                echo '</script>';
                exit();
            }else if(!$cTrue){
                echo '<script type="text/javascript">';
                echo 'alert("Wrong company code.");';
                echo 'window.history.back()';
                echo '</script>';
                exit();
            }else{
                echo '<script type="text/javascript">';
                echo 'alert("Username is taken");';
                echo 'window.history.back()';
                echo '</script>';
                exit();
            }
        }
// --- error ---

    }catch(Throwable $e){
        logAppError($e);
        try {
            $conn->rollback();
        } catch (Throwable $ignored) {
        }
        recordRateLimitFailure('signup', $ip, $username);

        $message = in_array($e->getMessage(), [
            'Could not send email. Please try again later.',
            'Email is not configured.',
        ], true)
            ? 'Account could not be created because verification email failed. Try again later.'
            : 'An error occured.Try Again.';

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }
    
    $conn -> close();
?>
