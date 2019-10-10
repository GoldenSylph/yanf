var express = require('express');
var app = express();
const port = process.env.PORT || 80;

app.use(express.static('src'));
app.use(express.static('build/contracts'));
app.use('/vendor', express.static(__dirname + '/node_modules/'));

app.get('/', function (req, res) {
  res.sendfile('index.html');
});

app.listen(port, async function() {
  console.log(`Listening on port ${port}!`);
});
