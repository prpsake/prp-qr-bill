// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_types from "rescript/lib/es6/js_types.js";

function reverseStr(x) {
  return x.split("").reverse().join("");
}

function blockStr(n, x) {
  var x$1 = Js_types.classify(x);
  if (typeof x$1 === "number") {
    return "";
  }
  if (x$1.TAG !== /* JSString */1) {
    return "";
  }
  var x_ = x$1._0.replace(/\s/g, "");
  var pat = new RegExp("\\S{" + n + "}", "g");
  return x_.replace(pat, "$& ");
}

function blockStr3(param) {
  return blockStr("3", param);
}

function blockStr4(param) {
  return blockStr("4", param);
}

function blockStr5(param) {
  return blockStr("5", param);
}

function referenceBlockStr(x) {
  var x$1 = Js_types.classify(x);
  if (typeof x$1 === "number") {
    return "";
  }
  if (x$1.TAG !== /* JSString */1) {
    return "";
  }
  var xTrim = x$1._0.trim();
  if (xTrim.startsWith("RF")) {
    return blockStr("4", xTrim);
  }
  var head = xTrim.substring(0, 2);
  var tail = blockStr("5", xTrim.substring(2));
  return head + " " + tail;
}

function moneyFromScaledIntStr(n, x) {
  var x$1 = Js_types.classify(x);
  if (typeof x$1 === "number") {
    return "";
  }
  if (x$1.TAG !== /* JSString */1) {
    return "";
  }
  var xTrim = x$1._0.trim();
  return reverseStr(blockStr("3", reverseStr(xTrim.slice(0, -n | 0)))) + "." + xTrim.slice(-n | 0);
}

function moneyFromScaledIntStr2(param) {
  return moneyFromScaledIntStr(2, param);
}

export {
  reverseStr ,
  blockStr ,
  blockStr3 ,
  blockStr4 ,
  blockStr5 ,
  referenceBlockStr ,
  moneyFromScaledIntStr ,
  moneyFromScaledIntStr2 ,
  
}
/* No side effect */
