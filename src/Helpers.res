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


