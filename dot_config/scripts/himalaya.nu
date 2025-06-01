export alias hi = himalaya

# list newly received emails, and select one to read.
export def em [] {
  himalaya --output json 
    | from json
    | each { |item| $"($item.id) | ($item.subject)" } 
    | to text
    | fzf
    | split column " | " 
    | get column1
    | get 0
    | himalaya message read $in
}
