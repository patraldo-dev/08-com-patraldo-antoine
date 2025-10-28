var fs = require("fs");
var tus = require("tus-js-client");

var path = process.env.HOME + "/AGR-Video-Studio/Projects/AGR_WAN/Monos-AGR/MonosBailando16.mp4"; // safe full path using environment variable for home
var file = fs.createReadStream(path);
var size = fs.statSync(path).size;
var mediaId = "";

var options = {
  endpoint: "https://api.cloudflare.com/client/v4/accounts/477082f5c9678c608889bd8f03f7b807/stream",
  headers: {
    Authorization: "Bearer Ug5dj6DnByrYHLqabEsVgXTbCLrBPITWVGG3QpLr",
  },
  chunkSize: 50 * 1024 * 1024, // Required a minimum chunk size of 5 MB. Here we use 50 MB.
  retryDelays: [0, 3000, 5000, 10000, 20000], // Indicates to tus-js-client the delays after which it will retry if the upload fails.
  metadata: {
    name: "MonosBailando-WM.mp4",
    filetype: "video/mp4",
    // Optional if you want to include a watermark
    // watermark: '6df18e5b03426fa5c295dafdf25c3323',
  },
  uploadSize: size,
  onError: function (error) {
    throw error;
  },
  onProgress: function (bytesUploaded, bytesTotal) {
    var percentage = ((bytesUploaded / bytesTotal) * 100).toFixed(2);
    console.log(bytesUploaded, bytesTotal, percentage + "%");
  },
  onSuccess: function () {
    console.log("Upload finished");
  },
  onAfterResponse: function (req, res) {
    return new Promise((resolve) => {
      var mediaIdHeader = res.getHeader("stream-media-id");
      if (mediaIdHeader) {
        mediaId = mediaIdHeader;
      }
      resolve();
    });
  },
};

var upload = new tus.Upload(file, options);
upload.start();
