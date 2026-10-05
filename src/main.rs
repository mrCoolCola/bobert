use teloxide::prelude::*;
use teloxide::types::KeyboardButton;
use teloxide::types::ReplyMarkup;
use std::process::Command;
use reqwest::Proxy;
use dotenvy::dotenv;
use std::env;
use std::sync::OnceLock;

mod torrent;

static USERS: OnceLock<Vec<i64>> = OnceLock::new();
static NICKNAMES: OnceLock<Vec<String>> = OnceLock::new();

fn set_users() -> &'static Vec<i64> {
    USERS.get_or_init(|| {
        dotenv().ok();
        let raw = env::var("BOBERT_USERS").expect("BOBERT_USERS not set in environment");
        raw.split(',')
            .map(|s| s.trim().parse().expect("Invalid number in USERS"))
            .collect()
    })
}

fn set_nicknames() -> &'static Vec<String> {
    NICKNAMES.get_or_init(|| {
        dotenv().ok();
        let raw = env::var("BOBERT_NICKNAMES").expect("NICKNAMES not set in environment");
        raw.split(',')
            .map(|s| s.trim().to_string())
            .collect()
    })
}

fn get_nickname(user_id: i64) -> &'static str {
    // Получаем ссылку на вектор пользователей (ленивая инициализация)
    let users = set_users();
    
    // Ищем индекс пользователя
    if let Some(index) = users.iter().position(|&id| id == user_id) {
        // Получаем вектор ников и берём элемент по индексу
        &set_nicknames()[index]   // &String автоматически становится &str
    } else {
        "n/a"
    }
}
// Создаем обычную клавиатуру с кнопками
fn get_keyboard() -> ReplyMarkup {
    let mut keyboard = Vec::new();
    keyboard.push(vec![KeyboardButton::new("🔌 Статус питания")]);
    keyboard.push(vec![KeyboardButton::new("🎮 Статус сервера")]);
    keyboard.push(vec![KeyboardButton::new("🎛 Сервисы")]);
    keyboard.push(vec![KeyboardButton::new("🔥 Температуры")]);
    keyboard.push(vec![KeyboardButton::new("🌐 Сеть")]);
    
    ReplyMarkup::keyboard(keyboard)
}

// Функция для получения статуса питания
fn get_power_status() -> String {
    let battery_path = "/sys/class/power_supply/BAT0";
    let charger_path = "/sys/class/power_supply/ADP1";
    
    let battery_status = match std::fs::read_to_string(format!("{}/status", battery_path)) {
        Ok(status) => status.trim().to_string(),
        Err(_) => "Неизвестно".to_string(),
    };
    
    let battery_capacity = match std::fs::read_to_string(format!("{}/capacity", battery_path)) {
        Ok(capacity) => capacity.trim().to_string(),
        Err(_) => "0".to_string(),
    };
    
    let ac_connected = match std::fs::read_to_string(format!("{}/online", charger_path)) {
        Ok(online) => online.trim() == "1",
        Err(_) => false,
    };
    
    format!(
        "⫍ Статус питания ⫎═════\n\
        Статус зарядного ⇛ {}\n\
        Статус аккумулятора ⇛ {}% ({})\n",
        ac_connected, battery_capacity, battery_status
    )
}

// Функция для получения статуса сервера
fn get_server_status() -> String {
    // Получаем свободное место на дисках
    let root_free = Command::new("df")
        .arg("-h")
        .arg("/")
        .output()
        .map(|output| {
            let output_str = String::from_utf8_lossy(&output.stdout);
            let lines: Vec<&str> = output_str.lines().collect();
            if lines.len() >= 2 {
                let parts: Vec<&str> = lines[1].split_whitespace().collect();
                if parts.len() >= 4 {
                    parts[3].to_string()
                } else {
                    "Ошибка".to_string()
                }
            } else {
                "Ошибка".to_string()
            }
        })
        .unwrap_or_else(|_| "Ошибка".to_string());
    
    // Получаем информацию о RAM
    let mem_info = Command::new("free")
        .arg("-h")
        .output()
        .map(|output| {
            let output_str = String::from_utf8_lossy(&output.stdout);
            let lines: Vec<&str> = output_str.lines().collect();
            if lines.len() >= 2 {
                let parts: Vec<&str> = lines[1].split_whitespace().collect();
                if parts.len() >= 4 {
                    let total = parts[1];
                    let available = parts[3];
                    let used_gb = parts[2];
                    format!("{} / {} ({} доступно)", used_gb, total, available)
                } else {
                    "Ошибка".to_string()
                }
            } else {
                "Ошибка".to_string()
            }
        })
        .unwrap_or_else(|_| "Ошибка".to_string());
    
    // Получаем загрузку CPU
    let cpu_load = Command::new("top")
        .arg("-bn1")
        .output()
        .map(|output| {
            let output_str = String::from_utf8_lossy(&output.stdout);
            for line in output_str.lines() {
                if line.contains("%Cpu(s)") {
                    let parts: Vec<&str> = line.split(',').collect();
                    if parts.len() >= 4 {
                        return format!("{}%", parts[0].trim().trim_start_matches("%Cpu(s):").trim());
                    }
                }
            }
            "Ошибка".to_string()
        })
        .unwrap_or_else(|_| "Ошибка".to_string());
    
    // Получаем аптайм
    let uptime = Command::new("uptime")
        .arg("-p")
        .output()
        .map(|output| {
            let output_str = String::from_utf8_lossy(&output.stdout);
            output_str.trim().to_string()
        })
        .unwrap_or_else(|_| "Ошибка".to_string());
    
    format!(
        "⫍ Статус сервера: ⫎═════\n\
        Свободное место (/) ⇛ {}\n\
        Озу ⇛ {}\n\
        Цпу ⇛ {}\n\
        ⫍ Аптайм ⫎═════\n\
        Хост: {}",
        root_free, mem_info, cpu_load, uptime
    )
}

// Функция для получения статуса сервисов
fn get_services_status() -> String {
    let services = vec![
        ("terraria", "terraria"),
        ("jellyfin", "jellyfin"),
        ("deluged", "deluged"),
        ("yggdrasil", "yggdrasil"),
        ("i2pd", "i2pd"),
        ("cronie", "cron"),
        ("byedpi", "byedpi"),
    ];
    
    let mut statuses = Vec::new();
    
    for (display_name, service_name) in services {
        let status = Command::new("systemctl")
            .args(["is-active", service_name])
            .output()
            .map(|output| {
                if output.status.success() {
                    format!(" ⌁ {} ✅", display_name)
                } else {
                    format!(" ⌁ {} ❌", display_name)
                }
            })
            .unwrap_or_else(|_| format!(" ⌁ {} ❓", display_name));
        
        statuses.push(status);
    }
    
    format!(
        "⫍ Сервисы ⫎═════\n{}\n\n\
        /run <сервис> - запустить сервис\n\
        /stop <сервис> - остановить сервис\n",
        statuses.join(",\n")
    )
}

// Функция для получения температур
fn get_temperatures() -> String {
    let temp_output = Command::new("sensors")
        .output()
        .map(|output| {
            String::from_utf8_lossy(&output.stdout).to_string()
        })
        .unwrap_or_else(|_| {
            "Не удалось получить данные о температуре.".to_string()
        });
    
    if temp_output.contains("°C") || temp_output.contains("°F") {
        format!("⫍ Температуры ⫎═════\n{}", temp_output)
    } else {
        // Альтернативный способ через thermal zones
        let thermal_zones = std::fs::read_dir("/sys/class/thermal/")
            .map(|entries| {
                let mut temps = Vec::new();
                for entry in entries.flatten() {
                    let zone_name = entry.file_name().to_string_lossy().to_string();
                    if zone_name.starts_with("thermal_zone") {
                        let temp_path = format!("/sys/class/thermal/{}/temp", zone_name);
                        if let Ok(content) = std::fs::read_to_string(&temp_path) {
                            if let Ok(temp_c) = content.trim().parse::<f32>() {
                                let temp_c = temp_c / 1000.0;
                                temps.push(format!("{}: {:.1}°C", zone_name, temp_c));
                            }
                        }
                    }
                }
                temps.join("\n")
            })
            .unwrap_or_else(|_| "Не удалось прочитать thermal zones".to_string());
        
        format!("⫍ Температуры ⫎═════\n{}", thermal_zones)
    }
}

// Функция для получения информации о сети
fn get_network_status() -> String {
    let interfaces_output = Command::new("ip")
        .arg("addr")
        .output()
        .map(|output| String::from_utf8_lossy(&output.stdout).to_string())
        .unwrap_or_else(|_| "Ошибка получения информации о сети".to_string());
    
    // Парсим вывод для получения основных интерфейсов
    let mut network_info = String::new();
    let mut current_interface = String::new();
    
    for line in interfaces_output.lines() {
        if !line.starts_with(' ') && line.contains(':') {
            // Новая секция интерфейса
            let parts: Vec<&str> = line.split(':').collect();
            if parts.len() >= 2 {
                current_interface = parts[1].trim().to_string();
                if !current_interface.is_empty() && !current_interface.contains("lo") {
                    network_info.push_str(&format!("\n📡 {}:\n", current_interface));
                }
            }
        } else if line.contains("inet ") && !current_interface.is_empty() && !current_interface.contains("lo") {
            let ip_info = line.trim();
            network_info.push_str(&format!("  IP: {}\n", ip_info));
        }
    }
    
    if network_info.is_empty() {
        network_info = "Не удалось получить информацию о сети".to_string();
    }
    
    format!("⫍ Сеть ⫎═════{}", network_info)
}

// Функция для управления сервисами
fn manage_service(command: &str, service: &str) -> String {
    let service_map = [
        ("terraria", "terraria"),
        ("jellyfin", "jellyfin"),
        ("deluged", "deluged"),
        ("yggdrasil", "yggdrasil"),
        ("i2pd", "i2pd"),
        ("cronie", "cron"),
        ("cron", "cron"),
        ("byedpi", "byedpi"),
    ];
    
    let real_service = service_map
        .iter()
        .find(|(display, _)| display == &service)
        .map(|(_, real)| *real)
        .unwrap_or(service);
    
    let systemctl_cmd = match command {
        "run" | "start" => "start",
        "stop" => "stop",
        "restart" => "restart",
        _ => return format!("Неизвестная команда: {}", command),
    };
    
    let output = Command::new("sudo")
        .args(["systemctl", systemctl_cmd, real_service])
        .output();
    
    match output {
        Ok(output) => {
            if output.status.success() {
                format!("✅ Сервис '{}' {}!", service, systemctl_cmd)
            } else {
                let error_msg = String::from_utf8_lossy(&output.stderr);
                format!("❌ Ошибка при {} сервиса '{}': {}", systemctl_cmd, service, error_msg)
            }
        }
        Err(e) => format!("❌ Ошибка выполнения команды: {}", e),
    }
}

async fn inform(bot: &Bot, id: i64, infa: String) {
    // let infa = infa
    //     .lines()
    //     // .map(|line| format!("║ {}", line))
    //     .collect::<Vec<_>>()
    //     .join("\n");
    log::info!("Отправляется текст: {}", infa);
    let message = format!("╔Оповещение от: {}\n{}", &get_nickname(id), infa);

    for &user_id in set_users().iter() {
        match bot
            .send_message(ChatId(user_id), &message)
            .parse_mode(teloxide::types::ParseMode::MarkdownV2)
            .await
        {
            Ok(_) => log::info!("Отправлено {} (Ник: {})", user_id, &get_nickname(user_id)),
            Err(e) => log::error!("Не отправлено {} (Ник: {}): {}", user_id, &get_nickname(user_id), e),
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    pretty_env_logger::init(); // init logger
    dotenv()?; // init .env file
    let proxy = Proxy::all("socks5://127.0.0.1:9050")?;
    let client = reqwest::Client::builder() // https client
        .proxy(proxy)
        .build()?;
    // get token from .env
    let token = env::var("BOBERT_TOKEN")
        .expect("BOBERT_TOKEN must be set in .env or shell to run the bot.");
    let bot = teloxide::Bot::with_client(token, client);
    let command = std::env::args().nth(1).expect("no command given");

    println!("Users: {:?}", set_users());
    println!("Nicknames: {:?}", set_nicknames());

    if command == "msg".to_string() {
        let text = &std::env::args().nth(2).expect("no text given");
        let escaped = teloxide::utils::markdown::escape(text);
        log::debug!("text: {:#?}", text);
        log::debug!("escaped: {:#?}", escaped);
        inform(&bot, 228, text.to_string()).await;
    } else {
        log::info!("Запускаем бота...");
        inform(&bot, 228, "Бот запущен".to_string()).await;
        teloxide::repl(bot, |bot: Bot, msg: Message| async move {
            let user_id = msg.chat.id.0;
            
            // Проверяем, есть ли пользователь в списке разрешенных
            if set_users().contains(&user_id) {
                if let Some(text) = msg.text() {
                    log::info!("Пользователь {} написал: {}", user_id, text);
                    match text {
                        "/start" => {
                            bot.send_message(msg.chat.id, "бебебе")
                                .reply_markup(get_keyboard())
                                .await?;
                        }
                        "🔌 Статус питания" => {
                            let status = get_power_status();
                            bot.send_message(msg.chat.id, status)
                                // .reply_markup(get_keyboard())
                                .await?;
                        }
                        "🎮 Статус сервера" => {
                            let status = get_server_status();
                            bot.send_message(msg.chat.id, status)
                                // .reply_markup(get_keyboard())
                                .await?;
                        }
                        "🎛 Сервисы" => {
                            let status = get_services_status();
                            bot.send_message(msg.chat.id, status)
                                // .reply_markup(get_keyboard())
                                .await?;
                        }
                        "🔥 Температуры" => {
                            let status = get_temperatures();
                            bot.send_message(msg.chat.id, status)
                                // .reply_markup(get_keyboard())
                                .await?;
                        }
                        "🌐 Сеть" => {
                            let status = get_network_status();
                            bot.send_message(msg.chat.id, status)
                                // .reply_markup(get_keyboard())
                                .await?;
                        }
                        _ => {
                            // commands with multiple parts
                            let parts: Vec<&str> = text.split_whitespace().collect();
                            if parts.len() >= 2 {
                                match parts[0] {
                                    "/run" => {
                                        let service = parts[1];
                                        let result = manage_service("run", service);
                                        bot.send_message(msg.chat.id, result)
                                            // .reply_markup(get_keyboard())
                                            .await?;
                                    }
                                    "/stop" => {
                                        let service = parts[1];
                                        let result = manage_service("stop", service);
                                        bot.send_message(msg.chat.id, result)
                                            // .reply_markup(get_keyboard())
                                            .await?;
                                    }
                                    "/restart" => {
                                        let service = parts[1];
                                        let result = manage_service("restart", service);
                                        bot.send_message(msg.chat.id, result)
                                            // .reply_markup(get_keyboard())
                                            .await?;
                                    }
                                    "/magnet" => {
                                        let magnet = parts[1];
                                        log::info!("Пользователь {} (Ник: {}) добавил магнитку {}", user_id, &get_nickname(user_id), magnet);
                                        torrent::add_magnet(&magnet).await;
                                    }
                                    _ => {
                                        bot.delete_message(msg.chat.id, msg.id).await?;
                                        inform(&bot, user_id, text.to_string()).await;
                                    }
                                }
                            } else {
                                bot.delete_message(msg.chat.id, msg.id).await?;
                                inform(&bot, user_id, teloxide::utils::markdown::escape(text)).await;                
                            }
                        }
                    }
                }
                Ok(())
            } else {
                bot.send_message(msg.chat.id, "⛔️ Извини, но у тебя нет доступа к этому боту.").await?;
                Ok(())
            }
        })
        .await;
    }
    Ok(())
}