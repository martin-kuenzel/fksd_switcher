const express = require('express');
const app = express();
const path = require('path');

const { exec } = require("child_process");

const PORT = process.env.PORT || 42421;
const ADDRESS = process.env.ADDRESS || '127.0.0.1';

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

app.listen( PORT, ADDRESS, () => console.log(`Listening on ${ADDRESS}:${PORT} ...`) )

const runCommand = (cmd,quiet) => {
  if(!cmd) return false;
  exec(cmd, (error, stdout, stderr) => {
    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    if(!quiet)
	console.log(`stdout: ${stdout}`);
  });
};

app.get('/switch',(req,res)=>{
  let cmd = 'Kein Kommando angegeben!';
  let msg = [cmd];
  if( req.query.t ){
    //console.log(req.query.s)

    // set state to req.query.state if 1, defaults to 0; // can only be 1 (on) or 0 (off)
    const state = req.query.s == 1 ? 1 : 0;

    // filter only strings with schema A to 12345E,
    // where 12345 (only once each) are the numeric dips set to "on" and 
    // A to E (only one) is the alphanumeric dip 
    const t = unescape(req.query.t).toLocaleUpperCase().split(',').filter(x=>x&&x.match(/^\s*[1-5]{0,5}[A-E]\s*$/i))

    if( t.length > 0 ) {
      msg.shift();
      cmd = t.map(x=> {
	msg.push('Schalte ' + x + ' auf ' + state)
        //console.log(msg[msg.length-1]);
        return './readableInput.sh ' + x + ' ' + state;
      }).join(' && ');
      cmd = '( SRC="$(realpath $(pwd))/../" && cd "$SRC" && ' + cmd + ')';
      runCommand(cmd, true);
    }
  };
  
  return res.end(JSON.stringify(msg));

});

app.use(express.static(path.join(__dirname,'/public')));
