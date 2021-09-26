let reverseStr: string => string =
  x =>
  Js.String2.split(x, "")
  ->Js.Array2.reverseInPlace
  ->Js.Array2.joinWith("")



let blockStr: string => string => string =
  n =>
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) => 
    let x_ = Js.String2.replaceByRe(x, %re("/\s/g"), "")
    let pat = Js.Re.fromStringWithFlags("\\S{"++ n ++"}", ~flags="g")
    Js.String2.replaceByRe(x_, pat, "$& ")
  | _ => ""
  }



let blockStr3 = blockStr("3")
let blockStr4 = blockStr("4")
let blockStr5 = blockStr("5")



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



