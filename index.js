var express = require('express');
var app = express();
const IPFS = require('ipfs');
const port = process.env.PORT;

app.use(express.static('src'));
app.use(express.static('build/contracts'));
app.use('/vendor', express.static(__dirname + '/node_modules/'));

app.get('/', function (req, res) {
  res.sendfile('index.html');
});

app.listen(port, async function() {
  const node = await IPFS.create();
  node.on('error', errorObject => console.error(errorObject));
  node.on('ready', () => console.log('IPFS node is ready'))
  console.log(`Listening on port ${port}!`);
});
