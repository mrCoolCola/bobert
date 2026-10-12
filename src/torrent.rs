use qbit::{Api, Credentials};
use qbit::parameters::{AddTorrentType, AddTorrentBuilder};

pub async fn add_magnet(magnet_url: &str) -> Result<(), Box<dyn std::error::Error>> {
    // если у боберта включен qbittorrentIntegration, аутентификация для локалхоста выключается
    let user = "";
    let pass = "";
    let url = "http://127.0.0.1:8080";
    let credentials = Credentials::new(user, pass);
    let client = Api::new_login(&url, credentials).await?;

    let params = AddTorrentBuilder::default()
        .torrents(AddTorrentType::Links(vec![magnet_url.to_string()]))
        .build()?;

    client.add_torrent(params).await?;
    // println!("добавил {}", magnet_url.to_string());
    Ok(())
}