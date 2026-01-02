const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');

const baseDir = path.resolve(__dirname, '..');
const shejiDir = path.join(baseDir, 'sheji');
const imagesDir = path.join(baseDir, 'static', 'images');

if (!fs.existsSync(imagesDir)) {
    fs.mkdirSync(imagesDir, { recursive: true });
}

function getAllHtmlFiles(dirPath, arrayOfFiles) {
    const files = fs.readdirSync(dirPath);
    arrayOfFiles = arrayOfFiles || [];

    files.forEach(function(file) {
        if (fs.statSync(dirPath + "/" + file).isDirectory()) {
            arrayOfFiles = getAllHtmlFiles(dirPath + "/" + file, arrayOfFiles);
        } else {
            if (file.endsWith('.html')) {
                arrayOfFiles.push(path.join(dirPath, file));
            }
        }
    });

    return arrayOfFiles;
}

const htmlFiles = getAllHtmlFiles(shejiDir);
const urlSet = new Set();

htmlFiles.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    // Regex for background-image: url("...")
    const regex = /url\("?(https:\/\/[^")]+)"?\)/g;
    let match;
    while ((match = regex.exec(content)) !== null) {
        urlSet.add(match[1]);
    }
    // Also check <img src="..."> if any
    const imgRegex = /src="?(https:\/\/[^"]+)"?/g;
    while ((match = imgRegex.exec(content)) !== null) {
        urlSet.add(match[1]);
    }
});

console.log(`Found ${urlSet.size} unique image URLs.`);

const downloadImage = (url, dest) => {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(dest);
        https.get(url, function(response) {
            response.pipe(file);
            file.on('finish', function() {
                file.close(() => resolve(dest));
            });
        }).on('error', function(err) {
            fs.unlink(dest, () => {}); // Delete the file async. (But we don't check result)
            reject(err.message);
        });
    });
};

async function processImages() {
    for (const url of urlSet) {
        const hash = crypto.createHash('md5').update(url).digest('hex');
        const ext = path.extname(url) || '.jpg'; // Default to jpg if unknown, though usually they have no ext or are messy
        const filename = `${hash}.jpg`; // Google content often returns jpg/webp. Let's force jpg or png.
        // Actually, let's keep it simple.
        
        const destPath = path.join(imagesDir, filename);
        if (fs.existsSync(destPath)) {
            console.log(`Skipping ${filename} (already exists)`);
            continue;
        }

        try {
            console.log(`Downloading ${url} -> ${filename}...`);
            await downloadImage(url, destPath);
        } catch (e) {
            console.error(`Failed to download ${url}: ${e}`);
        }
    }
    console.log("Image download complete.");
}

processImages();
