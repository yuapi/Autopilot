#!/usr/bin/env node
// wordcount: print the number of words in the text given as arguments or on stdin.
"use strict";

function countWords(text) {
  return text.trim().split(/\s+/).length;
}

function main(argv) {
  if (argv.length > 0) {
    console.log(countWords(argv.join(" ")));
    return;
  }
  let input = "";
  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => (input += chunk));
  process.stdin.on("end", () => console.log(countWords(input)));
}

module.exports = { countWords };
if (require.main === module) main(process.argv.slice(2));
