<?php 

// login.php — credential check, session login, rate limiting, redirect

// --- Initialization ---

            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                header('Location: /html/auth/login.html');
                exit();
            }

            try {
            require_once $_SERVER['DOCUMENT_ROOT'].'/php/common/secure_cookies.php';
            require_once $_SERVER['DOCUMENT_ROOT'].'/php/common/connect_to_DB.php';
            require_once $_SERVER['DOCUMENT_ROOT'].'/php/common/auth_helpers.php';
            require_once $_SERVER['DOCUMENT_ROOT'].'/php/auth/rate_limit_helpers.php';
            session_start();
            session_regenerate_id(true); // new session id on login (fixation mitigation)

            $username = $_POST['username'] ?? '';
            $password = $_POST['password'] ?? '';
            $ip = getClientIp();

// --- validation ---

            enforceRateLimitOrExit('login', $ip, $username);

            $hashedPasswordQuery = "SELECT password, emailVerified FROM user WHERE username = ?";
            $stmt= $conn->prepare($hashedPasswordQuery);
                $stmt->bind_param("s",$username);
                if ($stmt->execute()) {
                    $stmt->bind_result($hashedPassword, $emailVerified);
                    
                    if ($stmt->fetch()) {
// --- login ---

                        if (password_verify($password, $hashedPassword)) {
                            $stmt->close();
                            clearRateLimit('login', $ip, $username);

                            if (!$emailVerified) {
                                echo '<script type="text/javascript">';
                                echo 'alert("Please verify your email before logging in. Check your inbox for the verification link.");';
                                echo 'window.location.href = "/html/auth/login.html";';
                                echo '</script>';
                                exit();
                            }

                            $_SESSION['loggedin'] = true;
                            $_SESSION['username'] = $username;

                            $accessCache = null;
                            try {
                                $accessCache = getUserAccessPayload($conn);
                            } catch (Throwable $accessError) {
                                logAppError($accessError);
                            }

                            session_write_close();

                            echo '<script type="text/javascript">';
                            echo 'alert("Login successful!");';
                            if ($accessCache !== null) {
                                echo 'try { sessionStorage.setItem("navbarUserAccess", ' . json_encode(json_encode($accessCache)) . '); } catch (e) {}';
                            }
                            echo 'window.location.href = "/html/Starter/home.html";';
                            echo '</script>';
                            exit();
                        }else{
                            throw new Exception('Wrong password.', 2);
                        }
                    }else{
                        throw new Exception('Wrong username.', 3);
                    }
                }else{
                    throw new Exception('Could not look up user.', 1);
                }

// --- error ---

        }catch (Throwable $e) {
            $loginContext = 'login';
            if (!empty($username)) {
                $loginContext .= ' username=' . $username;
            }
            logAppError($e, $loginContext);
            $code = (int) $e->getCode();
            $msg = $e->getMessage();
            $isBadUsername = $code === 3 || $msg === '3' || $msg === 'Wrong username.';
            $isBadPassword = $code === 2 || $msg === '2' || $msg === 'Wrong password.';
            if ($isBadUsername || $isBadPassword) {
                recordRateLimitFailure('login', $ip, $username);
            }
            if ($isBadUsername) {
                echo '<script type="text/javascript">';
                echo 'alert("Wrong Username.");';
                echo 'window.history.back()';
                echo '</script>';
                exit();
            } else if ($isBadPassword) {
                echo '<script type="text/javascript">';
                echo 'alert("Wrong Password.");';
                echo 'window.history.back()';
                echo '</script>';
                exit();
            } else if (isDbUnavailable($e)) {
                respondDbUnavailable('html');
            } else {
                echo '<script type="text/javascript">';
                echo 'alert("An error occured");';
                echo 'window.history.back()';
                echo '</script>';
                exit();
            }
        }

?>
