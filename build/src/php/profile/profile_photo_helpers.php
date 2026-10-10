<?php

// profile_photo_helpers.php — profile photo upload, resize, serve

// --- Initialization ---

define('PROFILE_PHOTO_UPLOAD_DIR', dirname(__DIR__, 3) . '/uploads/profiles'); // {companyName}/{userId}_{hex}.jpg
const PROFILE_PHOTO_MAX_BYTES = 150 * 1024 * 1024; // pre-normalization upload cap
const PROFILE_PHOTO_INVALID_TYPE_MSG = 'Only JPG and PNG files are allowed.';
const PROFILE_PHOTO_ALLOWED_MIMES = [ // mime → stored extension
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
];
const PROFILE_PHOTO_EXTENSION_MAP = [ // filename ext → normalized ext
    'jpg' => 'jpg',
    'jpeg' => 'jpg',
    'png' => 'png',
];
const PROFILE_PHOTO_MAX_DIMENSION = 512; // longest edge after resize
const PROFILE_PHOTO_JPEG_QUALITY = 85; // output JPEG quality
const PROFILE_PHOTO_SEARCH_MAX_DIMENSION = 96; // longest edge for search list JPEG
const PROFILE_PHOTO_SEARCH_JPEG_QUALITY = 70; // smaller list file

// --- Upload validation ---

function profilePhotoUploadErrorMessage(int $code): string
{
    if ($code === UPLOAD_ERR_INI_SIZE || $code === UPLOAD_ERR_FORM_SIZE) {
        return 'Photo must be 150 MB or smaller.';
    }
    if ($code === UPLOAD_ERR_PARTIAL) {
        return 'Upload was interrupted. Please try again.';
    }
    if ($code === UPLOAD_ERR_NO_FILE) {
        return 'No photo uploaded.';
    }
    return 'Upload failed.';
}

function resolveProfilePhotoExtension(array $file, string $mime): ?string
{
    if (isset(PROFILE_PHOTO_ALLOWED_MIMES[$mime])) {
        return PROFILE_PHOTO_ALLOWED_MIMES[$mime];
    }

    $ext = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
    if (!isset(PROFILE_PHOTO_EXTENSION_MAP[$ext])) {
        return null;
    }

    $imageInfo = @getimagesize($file['tmp_name'] ?? '');
    if ($imageInfo === false) {
        return null;
    }

    return PROFILE_PHOTO_EXTENSION_MAP[$ext];
}

function validateUploadedProfilePhoto(array $file): array
{
    if (!isset($file['error']) || $file['error'] === UPLOAD_ERR_NO_FILE) {
        throw new Exception('No photo uploaded.');
    }

    if ($file['error'] !== UPLOAD_ERR_OK) {
        throw new Exception(profilePhotoUploadErrorMessage((int) $file['error']));
    }

    if (($file['size'] ?? 0) > PROFILE_PHOTO_MAX_BYTES) {
        throw new Exception('Photo must be 150 MB or smaller.');
    }

    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file($file['tmp_name']);
    $extension = resolveProfilePhotoExtension($file, $mime);
    if ($extension === null) {
        throw new Exception(PROFILE_PHOTO_INVALID_TYPE_MSG);
    }

    return [
        'tmp_name' => $file['tmp_name'],
        'extension' => $extension,
    ];
}

// --- Paths ---

function sanitizeProfilePhotoCompanyDirName(string $companyName): string
{
    $name = trim($companyName);
    $name = preg_replace('/[\\\\\/\:\*\?\"\<\>\|\x00-\x1F]+/', '_', $name) ?? '';
    $name = trim($name, " .");
    if ($name === '' || $name === '.' || $name === '..') {
        throw new Exception('Could not create upload directory.');
    }
    return $name;
}

function getCompanyNameById($conn, int $companyId): string
{
    $stmt = $conn->prepare('SELECT name FROM company WHERE id = ?');
    $stmt->bind_param('i', $companyId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if (!$row || empty($row['name'])) {
        throw new Exception(1);
    }
    return (string) $row['name'];
}

function getProfilePhotoPath(string $companyName, string $fileName, ?int $legacyCompanyId = null): string
{
    $fileName = basename($fileName);
    $byName = PROFILE_PHOTO_UPLOAD_DIR . '/' . sanitizeProfilePhotoCompanyDirName($companyName) . '/' . $fileName;
    if (is_file($byName) || $legacyCompanyId === null) {
        return $byName;
    }

    // legacy layout: uploads/profiles/{companyId}/...
    $byId = PROFILE_PHOTO_UPLOAD_DIR . '/' . $legacyCompanyId . '/' . $fileName;
    if (is_file($byId)) {
        return $byId;
    }

    return $byName;
}

function searchProfilePhotoFileName(string $profileFileName): string
{
    $base = pathinfo(basename($profileFileName), PATHINFO_FILENAME);

    return $base . '_search.jpg';
}

function ensureProfilePhotoCompanyDir(string $companyName, ?int $legacyCompanyId = null): string
{
    $dirName = sanitizeProfilePhotoCompanyDirName($companyName);
    $companyDir = PROFILE_PHOTO_UPLOAD_DIR . '/' . $dirName; // company-scoped upload folder

    if (!is_dir($companyDir) && $legacyCompanyId !== null) {
        $legacyDir = PROFILE_PHOTO_UPLOAD_DIR . '/' . $legacyCompanyId;
        if (is_dir($legacyDir)) {
            @rename($legacyDir, $companyDir);
        }
    }

    if (!is_dir($companyDir) && !mkdir($companyDir, 0755, true) && !is_dir($companyDir)) {
        throw new Exception('Could not create upload directory.');
    }
    return $companyDir;
}

function profilePhotoMimeFromExtension(string $extension): string
{
    return strtolower($extension) === 'png' ? 'image/png' : 'image/jpeg';
}

function profilePhotoMimeFromFileName(string $fileName): string
{
    $extension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
    return profilePhotoMimeFromExtension($extension);
}

// --- Image processing ---

function calculateProfilePhotoDimensions(int $width, int $height, int $max = PROFILE_PHOTO_MAX_DIMENSION): array
{
    if ($width <= $max && $height <= $max) {
        return [$width, $height];
    }

    $ratio = min($max / $width, $max / $height); // uniform downscale factor

    return [
        max(1, (int) round($width * $ratio)),
        max(1, (int) round($height * $ratio)),
    ];
}

function applyExifOrientation($image, string $sourcePath)
{
    if (!function_exists('exif_read_data')) {
        return $image;
    }

    $exif = @exif_read_data($sourcePath);
    if (!is_array($exif) || !isset($exif['Orientation'])) {
        return $image;
    }

    return match ((int) $exif['Orientation']) {
        3 => imagerotate($image, 180, 0),
        6 => imagerotate($image, -90, 0),
        8 => imagerotate($image, 90, 0),
        default => $image,
    };
}

function renderProfilePhotoCanvas($source, int $targetWidth, int $targetHeight)
{
    $canvas = imagecreatetruecolor($targetWidth, $targetHeight);
    if ($canvas === false) {
        return false;
    }

    $white = imagecolorallocate($canvas, 255, 255, 255);
    imagefill($canvas, 0, 0, $white);
    imagealphablending($canvas, true);
    imagesavealpha($canvas, false);
    imagecopyresampled(
        $canvas,
        $source,
        0,
        0,
        0,
        0,
        $targetWidth,
        $targetHeight,
        imagesx($source),
        imagesy($source)
    );

    return $canvas;
}

function saveProfilePhotoCanvasAsJpeg($canvas, string $destinationPath, int $quality = PROFILE_PHOTO_JPEG_QUALITY): void
{
    imageinterlace($canvas, false);
    if (!imagejpeg($canvas, $destinationPath, $quality)) {
        throw new Exception('Could not save uploaded file.');
    }
}

function loadProfilePhotoImage(string $sourcePath, string $extension)
{
    $extension = strtolower($extension);
    $loader = $extension === 'png' ? 'imagecreatefrompng' : 'imagecreatefromjpeg'; // GD loader by type
    if (!function_exists($loader)) {
        throw new Exception(PROFILE_PHOTO_INVALID_TYPE_MSG);
    }

    $source = @$loader($sourcePath);
    if ($source === false) {
        throw new Exception(PROFILE_PHOTO_INVALID_TYPE_MSG);
    }

    if ($extension === 'png') {
        imagealphablending($source, true);
        imagesavealpha($source, true);
    } else {
        $source = applyExifOrientation($source, $sourcePath);
    }

    return $source;
}

function writeSearchProfilePhotoFile(string $sourcePath, string $destinationPath): void
{
    if (!function_exists('imagecreatefromjpeg') || !is_file($sourcePath)) {
        throw new Exception('Could not save uploaded file.');
    }

    $info = @getimagesize($sourcePath);
    if ($info === false) {
        throw new Exception('Could not save uploaded file.');
    }

    $extension = $info[2] === IMAGETYPE_PNG ? 'png' : 'jpg';
    $previousMemoryLimit = ini_get('memory_limit'); // restore after GD work
    ini_set('memory_limit', '768M');

    try {
        $source = loadProfilePhotoImage($sourcePath, $extension);
        [$targetWidth, $targetHeight] = calculateProfilePhotoDimensions(
            imagesx($source),
            imagesy($source),
            PROFILE_PHOTO_SEARCH_MAX_DIMENSION
        );
        $canvas = renderProfilePhotoCanvas($source, $targetWidth, $targetHeight);
        imagedestroy($source);

        if ($canvas === false) {
            throw new Exception('Could not save uploaded file.');
        }

        saveProfilePhotoCanvasAsJpeg($canvas, $destinationPath, PROFILE_PHOTO_SEARCH_JPEG_QUALITY);
        imagedestroy($canvas);
    } finally {
        if ($previousMemoryLimit !== false) {
            ini_set('memory_limit', (string) $previousMemoryLimit);
        }
    }
}

function optimizeProfilePhotoFileInPlace(string $path): void
{
    if (!function_exists('imagecreatefromjpeg') || !is_file($path)) {
        return;
    }

    $previousMemoryLimit = ini_get('memory_limit'); // restore after GD work
    ini_set('memory_limit', '768M');

    try {
        $info = @getimagesize($path);
        if ($info === false) {
            return;
        }

        [$width, $height] = [$info[0], $info[1]];
        if ($width <= PROFILE_PHOTO_MAX_DIMENSION && $height <= PROFILE_PHOTO_MAX_DIMENSION) {
            return;
        }

        $extension = $info[2] === IMAGETYPE_PNG ? 'png' : 'jpg';
        $source = loadProfilePhotoImage($path, $extension);
        [$targetWidth, $targetHeight] = calculateProfilePhotoDimensions($width, $height);
        $canvas = renderProfilePhotoCanvas($source, $targetWidth, $targetHeight);
        imagedestroy($source);

        if ($canvas === false) {
            throw new Exception('Could not save uploaded file.');
        }

        saveProfilePhotoCanvasAsJpeg($canvas, $path);
        imagedestroy($canvas);
    } finally {
        if ($previousMemoryLimit !== false) {
            ini_set('memory_limit', (string) $previousMemoryLimit);
        }
    }
}

function normalizeProfilePhotoFromUpload(string $sourcePath, string $destinationPath, string $extension): void
{
    if (!function_exists('imagecreatefromjpeg')) {
        if (!move_uploaded_file($sourcePath, $destinationPath)) {
            throw new Exception('Could not save uploaded file.');
        }
        optimizeProfilePhotoFileInPlace($destinationPath);
        return;
    }

    $previousMemoryLimit = ini_get('memory_limit'); // restore after GD work
    ini_set('memory_limit', '768M');

    try {
        $source = loadProfilePhotoImage($sourcePath, $extension);
        [$targetWidth, $targetHeight] = calculateProfilePhotoDimensions(imagesx($source), imagesy($source));
        $canvas = renderProfilePhotoCanvas($source, $targetWidth, $targetHeight);
        imagedestroy($source);

        if ($canvas === false) {
            throw new Exception('Could not save uploaded file.');
        }

        saveProfilePhotoCanvasAsJpeg($canvas, $destinationPath);
        imagedestroy($canvas);
    } finally {
        if ($previousMemoryLimit !== false) {
            ini_set('memory_limit', (string) $previousMemoryLimit);
        }
    }
}

// --- Save and delete ---

function saveProfilePhotoFile(array $upload, string $companyName, int $userId, ?int $legacyCompanyId = null): string
{
    $companyDir = ensureProfilePhotoCompanyDir($companyName, $legacyCompanyId);
    $storedName = $userId . '_' . bin2hex(random_bytes(16)) . '.jpg'; // always stored as JPEG
    $destination = $companyDir . '/' . $storedName;
    $searchName = searchProfilePhotoFileName($storedName);
    $searchDestination = $companyDir . '/' . $searchName;

    try {
        normalizeProfilePhotoFromUpload($upload['tmp_name'], $destination, $upload['extension']);
        writeSearchProfilePhotoFile($destination, $searchDestination);
    } catch (Throwable $e) {
        if (is_file($destination)) {
            unlink($destination);
        }
        if (is_file($searchDestination)) {
            unlink($searchDestination);
        }
        throw $e;
    }

    return $storedName;
}

function deleteProfilePhotoFile(string $companyName, string $fileName, ?int $legacyCompanyId = null): void
{
    if ($fileName === '') {
        return;
    }

    $path = getProfilePhotoPath($companyName, $fileName, $legacyCompanyId);
    if (is_file($path)) {
        unlink($path);
    }

    $searchPath = getProfilePhotoPath($companyName, searchProfilePhotoFileName($fileName), $legacyCompanyId);
    if (is_file($searchPath)) {
        unlink($searchPath);
    }
}

function ensureSearchProfilePhotoFile(string $companyName, string $profileFileName, ?int $legacyCompanyId = null): string
{
    $searchName = searchProfilePhotoFileName($profileFileName);
    $searchPath = getProfilePhotoPath($companyName, $searchName, $legacyCompanyId);
    if (is_file($searchPath)) {
        return $searchName;
    }

    $profilePath = getProfilePhotoPath($companyName, $profileFileName, $legacyCompanyId);
    if (!is_file($profilePath)) {
        throw new Exception('Photo not found.');
    }

    $searchPath = dirname($profilePath) . '/' . $searchName;
    writeSearchProfilePhotoFile($profilePath, $searchPath);

    return $searchName;
}

// --- Database and serve ---

function getProfilePhotoFileName($conn, int $userId): ?string
{
    $stmt = $conn->prepare('SELECT profilePhotoFile FROM user WHERE id = ?');
    $stmt->bind_param('i', $userId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row || empty($row['profilePhotoFile'])) {
        return null;
    }

    return $row['profilePhotoFile'];
}

function userHasProfilePhotoExpr(): string
{
    return "(u.profilePhotoFile IS NOT NULL AND u.profilePhotoFile <> '')";
}

function serveProfilePhotoFile(string $companyName, string $fileName, ?int $legacyCompanyId = null, bool $allowBrowserCache = false): void
{
    while (ob_get_level() > 0) {
        ob_end_clean();
    }

    $path = getProfilePhotoPath($companyName, $fileName, $legacyCompanyId);
    if (!is_file($path)) {
        throw new Exception('Photo not found.');
    }

    if (!$allowBrowserCache) {
        optimizeProfilePhotoFileInPlace($path);
    }

    $mime = profilePhotoMimeFromFileName($fileName);
    $size = filesize($path);
    if ($size === false) {
        throw new Exception('Photo not found.');
    }

    header('Content-Type: ' . $mime);
    header('Content-Length: ' . $size);
    header('Content-Disposition: inline; filename="' . basename($fileName) . '"');
    if ($allowBrowserCache) {
        header('Cache-Control: private, max-age=86400');
    } else {
        header('Cache-Control: private, no-cache');
    }
    header('X-Content-Type-Options: nosniff');
    readfile($path);
    exit();
}
