use byondapi::{global_call::call_global, value::ByondValue};
use rustrict::{Censor, CensorStr, Replacements, Type};

#[byondapi::bind]
fn twitch_sanitize(message: ByondValue) -> eyre::Result<ByondValue> {
    let str = message.get_string()?;
    let censored = str.censor();

    Ok(ByondValue::try_from(censored)?)
}
