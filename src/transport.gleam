pub type Transport {
    Transport(
        url: String,
        token: String,
    )
}

pub fn new(url: String, token: String) -> Result(Transport, String) { //либо Ok(Transport), либо Error(String)
    case url, token {
        "", _ -> Error("Invalid URL")
        _, "" -> Error("Invalid Token")
        _, _ -> Ok(Transport(url, token))
    }
}

// pub fn send(transport: Transport, event: Event) -> Decoder {

// }