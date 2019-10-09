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

app.listen(port, function(){
  const node = IPFS.create().then((result) => {
    console.log(`Created IPFS node ${node} with result ${result}`);
  });
  node.on('error', errorObject => console.error(errorObject));
  node.on('ready', () => console.log("ipfs node is ready to use..."))
  console.log(`Listening on port ${port}!`);
});
