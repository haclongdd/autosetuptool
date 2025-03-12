const express = require('express');
const { exec } = require('child_process');
const https = require('https');
const fs = require('fs');
const app = express();

// Sử dụng cổng từ Render, hoặc 3001 nếu không có
const port = process.env.PORT || 3001;

// Phục vụ các file tĩnh
app.use(express.static('public'));

// Lưu tiến độ
let progress = 0;

// Hàm tải Pi Network (chỉ tải file, không chạy .exe)
async function installPiNetwork() {
    const piInstaller = '/tmp/Pi_Network_Setup.exe'; // Thư mục tạm trên Render
    const url = 'https://downloads.minepi.com/Pi%20Network%20Setup%200.5.0.exe';
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(piInstaller);
        https.get(url, (response) => {
            response.pipe(file);
            file.on('finish', () => {
                file.close(() => resolve('Tải Pi Network hoàn tất! (File đã tải về /tmp)'));
            });
        }).on('error', (err) => {
            reject(`Lỗi khi tải: ${err.message}`);
        });
    });
}

// Hàm cập nhật hệ thống (thay WSL2)
async function updateSystem() {
    return new Promise((resolve, reject) => {
        exec('apt-get update && apt-get upgrade -y', (err, stdout, stderr) => {
            if (err) reject(`Lỗi khi cập nhật: ${err.message}`);
            else resolve('Cập nhật hệ thống hoàn tất!');
        });
    });
}

// Hàm kiểm tra Docker (thay Install-Docker)
async function checkDocker() {
    return new Promise((resolve, reject) => {
        exec('docker --version', (err, stdout, stderr) => {
            if (err) reject('Docker không khả dụng hoặc lỗi');
            else resolve('Docker đã sẵn sàng!');
        });
    });
}

// API để chạy các tác vụ
app.get('/run-task/:taskId', async (req, res) => {
    const taskId = req.params.taskId;
    progress = 0;
    res.write(`Bắt đầu nhiệm vụ ${taskId}\n`); // Gửi phản hồi ban đầu

    let result;
    try {
        switch (taskId) {
            case '1':
                result = await installPiNetwork();
                break;
            case '5':
                result = await updateSystem();
                break;
            case '6':
                result = await checkDocker();
                break;
            default:
                result = 'Task ID không hợp lệ';
        }
        progress = 100;
        res.end(result); // Kết thúc phản hồi với kết quả
    } catch (error) {
        progress = 0;
        res.status(500).end(`Lỗi: ${error}`); // Kết thúc với lỗi
    }
});

// API để lấy tiến độ
app.get('/progress', (req, res) => {
    res.json({ progress });
});

// Giả lập tiến độ
setInterval(() => {
    if (progress < 90) progress += 10;
}, 1000);

// Khởi động server
app.listen(port, '0.0.0.0', () => {
    console.log(`Server chạy tại http://0.0.0.0:${port}`);
});