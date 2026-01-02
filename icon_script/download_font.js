const fs = require('fs');
const https = require('https');
const path = require('path');

const fontUrl = 'https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsOutlined%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf';
const codepointsUrl = 'https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsOutlined%5BFILL%2CGRAD%2Copsz%2Cwght%5D.codepoints';

const downloadFile = (url, dest) => {
    return new Promise((resolve, reject) => {
        const getRequest = (currentUrl) => {
            https.get(currentUrl, (response) => {
                if (response.statusCode === 302 || response.statusCode === 301) {
                    // Follow redirect
                    getRequest(response.headers.location);
                    return;
                }
                
                if (response.statusCode !== 200) {
                    reject(new Error(`Failed to download ${url}: ${response.statusCode}`));
                    return;
                }

                const file = fs.createWriteStream(dest);
                response.pipe(file);
                file.on('finish', () => {
                    file.close(() => resolve(dest));
                });
            }).on('error', (err) => {
                fs.unlink(dest, () => {});
                reject(err);
            });
        };
        getRequest(url);
    });
};

async function main() {
    console.log("Downloading Font and Codepoints...");
    try {
        await downloadFile(fontUrl, 'static/fonts/MaterialSymbolsOutlined.ttf');
        console.log("Downloaded TTF.");
        await downloadFile(codepointsUrl, 'static/fonts/MaterialSymbolsOutlined.codepoints');
        console.log("Downloaded Codepoints.");
    } catch (error) {
        console.error("Download failed:", error);
    }
}

main();