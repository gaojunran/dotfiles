def mihome-post [
  url_part: string,
  data: string
] {
  http post $"http://localhost:8123/api/services/($url_part)" $data --headers [
    Authorization $"Bearer ($env.HOMEASSISTANT_TOKEN)"
    "Content-Type" "application/json"
  ]
}

def mihome-get-state [
  url_part: string
] {
  http get $"http://localhost:8123/api/states/($url_part)" --headers [
    Authorization $"Bearer ($env.HOMEASSISTANT_TOKEN)"
  ]
}

export def lamp [state?: string] {
  if $state == null {  # toggle by default
    mihome-post "light/toggle" ({
      "entity_id": $"light.($env.MIHOME_LAMP_ID)"
    } | to json)
  } # else to do
}

export def ac [state?: string] {
  if $state == null {  # toggle by default
    mihome-post "climate/toggle" ({
      "entity_id": $"climate.($env.MIHOME_AC_ID)"
    } | to json)
  } else if $state == "inc" {
    let temp = (mihome-get-state $"climate.($env.MIHOME_AC_ID)" | get attributes | get temperature) + 1
    mihome-post "climate/set_temperature" ({
      "entity_id": $"climate.($env.MIHOME_AC_ID)",
      "temperature": $temp
    } | to json)
  } else if $state == "dec" {
    let temp = (mihome-get-state $"climate.($env.MIHOME_AC_ID)" | get attributes | get temperature) - 1
    mihome-post "climate/set_temperature" ({
      "entity_id": $"climate.($env.MIHOME_AC_ID)",
      "temperature": $temp
    } | to json)
  } # else to do
}
