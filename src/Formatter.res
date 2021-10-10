/** 

`removeWhitespace(x)` 

Takes string `x` and returns a string from `x` without whitespace.
Returns an emtpy string if `x` is not a string.

*/
let removeWhitespace: string => string =
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) => Js.String2.replaceByRe(x, %re("/\s/g"), "")
  | _ => ""
  }



/** 

`reverseStr(x)` 

Takes string `x` and returns a reversed string from `x`.

*/
let reverseStr: string => string =
  x =>
  Js.String2.split(x, "")
  ->Js.Array2.reverseInPlace
  ->Js.Array2.joinWith("")



/**

`blockStr(n, x)`

Takes integer `n`, string `x` and returns a string from `x` grouped in 
character-blocks of length `n` seperated by spaces.

Examples: 
- n = 3, x = "123456789" ->"123 456 789"
- n = 4, x = "abcdefgh" ->"abcd efgh"

*/
let blockStr: int => string => string =
  n =>
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) => 
    let x_ = Js.String2.replaceByRe(x, %re("/\s/g"), "")
    let pat = Js.Re.fromStringWithFlags("\\S{"++Belt.Int.toString(n)++"}", ~flags="g")
    Js.String2.replaceByRe(x_, pat, "$& ")
  | _ => ""
  }



let blockStr3 = blockStr(3)
let blockStr4 = blockStr(4)
let blockStr5 = blockStr(5)



/**

referenceBlockStr(x)

Takes string `x`, if `x` starts with "RF", returns a string from `x` in 
the Creditor Reference format (CROOKS 11649), else returns a string from `x` 
in the QR-Reference format.

Examples:
- x = "RF18539007547034" ->"RF18 5390 0754 7034"
- x = "213455654786322980076652786" ->"21 34556 54786 32298 00766 52786"

*/
let referenceBlockStr: string => string =
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) =>
    let xTrim = Js.String2.trim(x)
    switch Js.String2.startsWith(xTrim, "RF") {
    | true => blockStr4(xTrim)
    | false => 
      let head = Js.String2.substring(xTrim, ~from=0, ~to_=2)
      let tail = blockStr5(Js.String2.substringToEnd(xTrim, ~from=2))
      head++ " " ++tail
    }
  | _ => ""
  }



/**

moneyFromScaledIntStr(n, x)

Takes integer `n`, string `x` and returns a string from `x`

*/
let moneyFromScaledIntStr: int => string => string =
  n =>
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) =>
    let xTrim = Js.String2.trim(x)
    xTrim
    ->Js.String2.slice(~from=0, ~to_=-n)
    ->reverseStr
    ->blockStr3
    ->reverseStr
    ++ "." 
    ++ Js.String2.sliceToEnd(xTrim, ~from=-n)
  | _ => ""
  }



let moneyFromScaledIntStr2 = moneyFromScaledIntStr(2)
