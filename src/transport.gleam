pub type Transport {
    Transport(
        url: String
    )
}

const default_url = "https://k1.hawk.so/"

pub fn new(_url: String) -> Transport {
    case url {
        "" -> Transport(default_url)
        _ -> Transport(url)
    }
}

// pub fn send(transport: Transport, event: Event) -> Decoder {

// }