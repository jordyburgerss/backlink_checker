<?php
// API credentials
$api_key = '9de9760c3fea8aa142b194168496113a';
$api_endpoint = 'https://api.backlinkapi.com/v1/backlinks';
$search_url = 'https://fondby.com'; // Replace with the URL you want to check

// Initialize cURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "$api_endpoint?url=$search_url");
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: Bearer $api_key"
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

// Execute and get response
$response = curl_exec($ch);
curl_close($ch);

if ($response === false) {
    echo "Failed to fetch backlinks.\n";
} else {
    $data = json_decode($response, true);
    if (isset($data['data']['backlinks'])) {
        $backlinks = $data['data']['backlinks'];
        echo "Backlinks for $search_url:\n";
        foreach ($backlink as $backlinks) {
            echo "- " . $backlink['url'] . "\n";
        }
    } else {
        echo "No backlinks found for $search_url.\n";
    }
}
?>
