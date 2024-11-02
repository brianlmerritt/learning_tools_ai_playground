<?php

require 'vendor/autoload.php';

use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;

// Define network hosts and ports
$services = [
    'weaviate' => ['host' => 'weaviate', 'port' => 8081],
    'ollama' => ['host' => 'ollama', 'port' => 11434],
    'solr' => ['host' => 'solr', 'port' => 8983],
    'elasticsearch' => ['host' => 'elasticsearch', 'port' => 9200],
    'tika' => ['host' => 'tika', 'port' => 9998]
];

/**
 * Check if an environment variable exists
 */
function checkEnvVar(string $varName): bool {
    return !empty(getenv($varName));
}

/**
 * Check if a port is open
 */
function checkPort(string $host, int $port, string $name): string {
    $connection = @fsockopen($host, $port, $errno, $errstr, 5);
    if (is_resource($connection)) {
        fclose($connection);
        $status = "$name: 'Available'";
        echo $status . PHP_EOL;
        return $status;
    } else {
        $status = "$name: 'NOT Available' ($errstr)";
        echo $status . PHP_EOL;
        return $status;
    }
}

// Check AI services
echo "Checking AI services:" . PHP_EOL;

// OpenAI
$openaiApiKey = checkEnvVar('OPENAI_API_KEY');
echo "OpenAI API Key: " . ($openaiApiKey ? 'Present' : 'Missing') . PHP_EOL;

// Anthropic
$anthropicApiKey = checkEnvVar('ANTHROPIC_API_KEY');
echo "Anthropic API Key: " . ($anthropicApiKey ? 'Present' : 'Missing') . PHP_EOL;

// Hugging Face
$huggingfaceApiKey = checkEnvVar('HUGGINGFACE_API_KEY');
echo "Hugging Face API Key: " . ($huggingfaceApiKey ? 'Present' : 'Missing') . PHP_EOL;

echo "\nChecking database services:" . PHP_EOL;

// Check all services
foreach ($services as $name => $config) {
    $status = checkPort($config['host'], $config['port'], strtoupper($name));
    
    // Special handling for Ollama
    if ($name === 'ollama' && str_contains($status, 'Available')) {
        try {
            $client = new Client(['base_uri' => "http://{$config['host']}:{$config['port']}"]);
            
            // Check available models
            $response = $client->get('/api/tags');
            if ($response->getStatusCode() === 200) {
                $models = json_decode($response->getBody(), true);
                echo "Available OLLAMA models:" . PHP_EOL;
                foreach ($models['models'] ?? [] as $model) {
                    echo "- " . ($model['name'] ?? 'Unknown') . PHP_EOL;
                    echo "  Details: " . json_encode($model['details'] ?? []) . PHP_EOL;
                }
                
                // Get version info
                $statusResponse = $client->get('/api/version');
                echo "\nOLLAMA Status response code: " . $statusResponse->getStatusCode() . PHP_EOL;
                echo "OLLAMA Status response: " . $statusResponse->getBody() . PHP_EOL;
                
                // Check embeddings
                $embedResponse = $client->get('/api/embeddings');
                echo "\nOLLAMA Embeddings response code: " . $embedResponse->getStatusCode() . PHP_EOL;
                echo "OLLAMA Embeddings response: " . $embedResponse->getBody() . PHP_EOL;
            }
        } catch (GuzzleException $e) {
            echo "OLLAMA API Check Failed: " . $e->getMessage() . PHP_EOL;
        }
    }
}

echo "\nCheck complete." . PHP_EOL; 