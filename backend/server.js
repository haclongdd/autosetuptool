const express = require('express');
const { exec } = require('child_process');
const app = express();
const port = 3001; // Port bạn đã chọn

// Phục vụ các file tĩnh (như index.html)
app.use(express.static(__dirname));

// API để chạy các tác vụ PowerShell
app.get('/run-task/:taskId', (req, res) => {
    const taskId = req.params.taskId;
    const psCommand = `powershell -ExecutionPolicy Bypass -File "C:\\Users\\admin\\Desktop\\web\\script.ps1" ${taskId}`;

    exec(psCommand, { shell: 'powershell.exe' }, (error, stdout, stderr) => {
        if (error) {
            console.error(`Lỗi: ${error.message}`);
            return res.status(500).send(`Lỗi: ${error.message}`);
        }
        if (stderr) {
            console.error(`Stderr: ${stderr}`);
            return res.status(500).send(`Lỗi: ${stderr}`);
        }
        console.log(`Kết quả: ${stdout}`);
        res.send(`Đã chạy nhiệm vụ ${taskId}: ${stdout}`);
    });
});

app.listen(port, () => {
    console.log(`Server chạy tại http://localhost:${port}`);
});