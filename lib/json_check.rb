# check for valid json
module JsonCheck
  # Check is string parse to json
  def valid_json?(json)
    JSON.parse(json)
    return true
  rescue JSON::ParserError
    return false
  end
end
