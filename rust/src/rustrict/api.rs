use crate::rustrict::statics::*;
use byondapi::value::ByondValue;
use rustrict::Censor;

#[byondapi::bind]
fn twitch_sanitize(message: ByondValue) -> eyre::Result<ByondValue> {
    let str = message.get_string()?;
    // Builtin censor() doing unwanted things, if it possible - use collect.
    let censored_string: String = Censor::from_str(&str)
        .with_trie(&TWITCH_BADWORDS)
        .with_ignore_false_positives(true)
        .collect();

    Ok(ByondValue::try_from(censored_string)?)
}
