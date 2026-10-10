<?php

// MailService.php — SMTP email sending

// --- Initialization ---

require_once dirname(__DIR__, 4) . '/vendor/autoload.php';
require_once __DIR__ . '/../../logs/log_helpers.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

class MailService
{
// --- Mailer setup ---

    private static function config(): array
    {
        return require __DIR__ . '/mail_config.php';
    }

    private static function createMailer(?string $fromName = null): PHPMailer
    {
        $config = self::config();

        $mail = new PHPMailer(true);
        $mail->isSMTP();
        $mail->Host = $config['host'];
        $mail->SMTPAuth = true;
        $mail->Username = $config['user'];
        $mail->Password = $config['pass'];
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = $config['port'];
        $mail->CharSet = PHPMailer::CHARSET_UTF8;

        $mail->setFrom($config['user'], $fromName ?? $config['from_name']);

        return $mail;
    }

    private static function sendHtml(string $to, string $subject, string $body, ?string $fromName = null, ?string $replyTo = null): bool
    {
        $config = self::config();
        if (empty($config['host']) || empty($config['user'])) {
            throw new Exception('Email is not configured.');
        }

        try {
            $mail = self::createMailer($fromName);
            $mail->addAddress($to);
            if ($replyTo !== null && $replyTo !== '') {
                $mail->addReplyTo($replyTo);
            }
            $mail->isHTML(true);
            $mail->Subject = $subject;
            $mail->Body = $body;
            $mail->send();
            return true;
        } catch (PHPMailerException $e) {
            logAppError($e, 'MailService');
            throw new Exception('Could not send email. Please try again later.');
        }
    }

    private static function appName(): string
    {
        $name = trim((string) (self::config()['from_name'] ?? ''));
        return $name !== '' ? $name : 'Our Information System';
    }

// --- Account emails ---

    public static function sendVerificationEmail(string $to, string $token, string $username): bool
    {
        $config = self::config();
        $url = $config['base_url'] . '/php/auth/verifyEmail.php?token=' . urlencode($token);
        $safeName = htmlspecialchars($username, ENT_QUOTES, 'UTF-8');

        $body = "<h3>Welcome, {$safeName}!</h3>
            <p>Click here to verify your account:</p>
            <a href='{$url}'>Verify account</a>
            <p>Link works for 24 hours only.</p>";

        return self::sendHtml($to, 'Verify account', $body);
    }

    public static function sendEmailChangeVerification(string $to, string $token, string $username): bool
    {
        $config = self::config();
        $url = $config['base_url'] . '/php/auth/verifyEmail.php?token=' . urlencode($token);
        $safeName = htmlspecialchars($username, ENT_QUOTES, 'UTF-8');

        $body = "<h3>Confirm your new email, {$safeName}</h3>
            <p>Click here to confirm this email address:</p>
            <a href='{$url}'>Confirm email</a>
            <p>Link works for 24 hours only.</p>";

        return self::sendHtml($to, 'Confirm new email', $body);
    }

// --- Company emails ---

    public static function sendCompanyActivationToAdmin(string $companyName, string $requesterEmail, string $token): bool
    {
        $config = self::config();
        if (empty($config['user'])) {
            throw new Exception('Email is not configured.');
        }

        $url = $config['base_url'] . '/php/auth/approveCompany.php?token=' . urlencode($token);
        $safeCompany = htmlspecialchars($companyName, ENT_QUOTES, 'UTF-8');
        $safeEmail = htmlspecialchars($requesterEmail, ENT_QUOTES, 'UTF-8');

        $body = "<h3>Company registration — activation required</h3>
            <p>A new company has requested access to the information system.</p>
            <p><strong>Company:</strong> {$safeCompany}</p>
            <p><strong>Contact email:</strong> {$safeEmail}</p>
            <p>Click below to activate the account and send registration codes:</p>
            <p><a href='{$url}'>Activate company account</a></p>";

        return self::sendHtml($config['user'], 'Company activation request — ' . $companyName, $body);
    }

    public static function sendCompanyRegistrationQuestionnaire(string $to, string $companyName): bool
    {
        $config = self::config();
        if (empty($config['user'])) {
            throw new Exception('Email is not configured.');
        }

        $safeCompany = htmlspecialchars($companyName, ENT_QUOTES, 'UTF-8');
        $appName = htmlspecialchars(self::appName(), ENT_QUOTES, 'UTF-8');
        $subject = 'Registration Application Confirmation & Subscription Plan Assessment - ' . $companyName;

        $body = "<p>Dear <b>{$safeCompany}</b>,</p>
            <p>Thank you for submitting your registration application to our information system.</p>
            <p>In order to complete the process and determine the most appropriate and cost-effective subscription plan for your business needs, please <strong>reply to this email</strong> by selecting the applicable range for the following metrics:</p>
            <p><strong>1. Estimated Number of Employees:</strong></p>
            <ul>
                <li>Less than 20</li>
                <li>21 – 50</li>
                <li>51 – 100</li>
                <li>100+</li>
            </ul>
            <p><strong>2. Expected Transaction Volume (per month):</strong></p>
            <ul>
                <li>Up to 10,000 transactions</li>
                <li>10,001 – 50,000 transactions</li>
                <li>50,001 – 100,000 transactions</li>
                <li>100,000+ transactions</li>
            </ul>
            <p>Once we receive your response and the required verification of your corporate email is completed, our sales department will send you the official financial offer for the use of the information system.</p>
            <p><em>Note: This is an automated message. Please use the &quot;Reply&quot; option to provide your details.</em></p>
            <p>Best regards,<br> <b> {$appName} </b> Support Team</p>";

        return self::sendHtml($to, $subject, $body, null, $config['user']);
    }

    public static function sendCompanyApproved(string $to, string $companyName, string $managerCode, string $employeeCode): bool
    {
        $safeCompany = htmlspecialchars($companyName, ENT_QUOTES, 'UTF-8');
        $safeManager = htmlspecialchars($managerCode, ENT_QUOTES, 'UTF-8');
        $safeEmployee = htmlspecialchars($employeeCode, ENT_QUOTES, 'UTF-8');
        $appName = htmlspecialchars(self::appName(), ENT_QUOTES, 'UTF-8');

        $body = "<h3>Your company is ready</h3>
            <p>Your company <strong>{$safeCompany}</strong> is now ready to operate on the {$appName} information system.</p>
            <p><strong>Manager code:</strong> {$safeManager}</p>
            <p><strong>Employee code:</strong> {$safeEmployee}</p>
            <p>You can now sign up using these codes.</p>";

        return self::sendHtml($to, 'Company account activated — ' . $companyName, $body);
    }

// --- Shift emails ---

    public static function sendShiftNotification(string $to, array $shiftDetails): bool
    {
        $employeeName = htmlspecialchars($shiftDetails['employeeName'] ?? 'Employee', ENT_QUOTES, 'UTF-8');
        $schedule = htmlspecialchars($shiftDetails['schedule'] ?? '', ENT_QUOTES, 'UTF-8');
        $startTime = htmlspecialchars($shiftDetails['startTime'] ?? '', ENT_QUOTES, 'UTF-8');
        $endTime = htmlspecialchars($shiftDetails['endTime'] ?? '', ENT_QUOTES, 'UTF-8');
        $fromName = $shiftDetails['companyName'] ?? self::config()['from_name'];

        $body = "<h3>New shift assigned</h3>
            <p>Hello {$employeeName},</p>
            <p>You have been assigned a new shift:</p>
            <p><strong>When:</strong> {$schedule}</p>
            <p><strong>Time:</strong> {$startTime} – {$endTime}</p>
            <p><i>Do not reply to this email.</i></p>";

        return self::sendHtml($to, 'New shift assignment', $body, $fromName);
    }

    public static function sendShiftDeletionNotification(string $to, array $shiftDetails): bool
    {
        $employeeName = htmlspecialchars($shiftDetails['employeeName'] ?? 'Employee', ENT_QUOTES, 'UTF-8');
        $schedule = htmlspecialchars($shiftDetails['schedule'] ?? '', ENT_QUOTES, 'UTF-8');
        $startTime = htmlspecialchars($shiftDetails['startTime'] ?? '', ENT_QUOTES, 'UTF-8');
        $endTime = htmlspecialchars($shiftDetails['endTime'] ?? '', ENT_QUOTES, 'UTF-8');
        $fromName = $shiftDetails['companyName'] ?? self::config()['from_name'];

        $body = "<h3>Shift removed</h3>
            <p>Hello {$employeeName},</p>
            <p>One of your shifts has been removed:</p>
            <p><strong>When:</strong> {$schedule}</p>
            <p><strong>Time:</strong> {$startTime} – {$endTime}</p>
            <p><i>Do not reply to this email.</i></p>";

        return self::sendHtml($to, 'Shift removed', $body, $fromName);
    }

// --- Recovery emails ---

    public static function sendPasswordResetEmail(string $to, string $token, string $username): bool
    {
        $config = self::config();
        $url = $config['base_url'] . '/html/auth/resetPassword.html?token=' . urlencode($token);
        $safeName = htmlspecialchars($username, ENT_QUOTES, 'UTF-8');

        $body = "<h3>Reset your password, {$safeName}</h3>
            <p>Click here to set a new password:</p>
            <a href='{$url}'>Reset password</a>
            <p>Link works for 24 hours only.</p>";

        return self::sendHtml($to, 'Reset password', $body);
    }

    public static function sendUsernameResetEmail(string $to, string $token, string $username): bool
    {
        $config = self::config();
        $url = $config['base_url'] . '/html/auth/resetUsername.html?token=' . urlencode($token);
        $safeName = htmlspecialchars($username, ENT_QUOTES, 'UTF-8');

        $body = "<h3>Change your username, {$safeName}</h3>
            <p>Click here to choose a new username:</p>
            <a href='{$url}'>Change username</a>
            <p>Link works for 24 hours only.</p>";

        return self::sendHtml($to, 'Change username', $body);
    }
}
