use rustrict::{Trie, Type};
use std::sync::LazyLock;

pub static TWITCH_BADWORDS: LazyLock<Trie> = LazyLock::new(|| {
    include_str!("censor/twitch_badwords.txt")
        .lines()
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(|line| (line, Type::PROFANE))
        .collect()
});
