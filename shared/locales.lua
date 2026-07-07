Locales = {}

Locales.nl = {
    no_permission = 'Je hebt geen toegang tot dit menu.',
    activity_started = 'Activiteit gestart.',
    activity_completed = 'Activiteit voltooid.',
    step_failed = 'Stap mislukt, probeer opnieuw.',
    step_cancelled = 'Actie geannuleerd, probeer opnieuw.',
    too_far = 'Je bent te ver weg.',
    not_enough_police = 'Er is niet genoeg politie aanwezig.',
    cooldown = 'Deze activiteit heeft nog cooldown.',
    missing_item = 'Je hebt niet genoeg items. Nodig: %sx %s.',
    missing_money = 'Je hebt niet genoeg geld. Nodig: %s %s.',
    already_busy = 'Je bent al bezig met een activiteit.',
    activity_disabled = 'Deze activiteit staat uit.',
    invalid_activity = 'Deze activiteit bestaat niet meer.',
    exploit = 'Ongeldige actie gedetecteerd.',
    door_locked = 'De deur is op slot gezet.',
    door_unlocked = 'De deur is geopend.',
    admin_saved = 'Activiteit opgeslagen.',
    admin_deleted = 'Activiteit verwijderd.',
    admin_error = 'Er ging iets mis.'
}

function _L(key, ...)
    local lang = 'nl'
    local str = Locales[lang] and Locales[lang][key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
