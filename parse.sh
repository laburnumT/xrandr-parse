#!/bin/bash

state0_json() {
        local connected
        local primary
        local current_config

        if grep -q "disconnected" <<<"${line}"; then
                connected=false
                current_config="{}"
        else
                connected=true
                local tmp_str
                tmp_str="$(grep -Po "\d+x\d+\+\d+\+\d+" <<<"${line}")"
                current_config="$(
                        jq --null-input \
                                --arg resolution "$(
                                        grep -Po "^\d+x\d+" <<<"${tmp_str}"
                                )" \
                                --arg offset "$(
                                        grep -Po "\d+\+\d+$" <<<"${tmp_str}"
                                )" \
                                '{
                                        "resolution": $resolution,
                                        "offset": $offset
                                }'
                )"
        fi
        if grep -q "primary" <<<"${line}"; then
                primary=true
        else
                primary=false
        fi

        jq \
                --arg display "${display_name}" \
                --argjson connected "${connected}" \
                --argjson primary "${primary}" \
                --argjson current_config "${current_config}" \
                '. += [{
                        "name": $display,
                        "connected": $connected,
                        "primary": $primary,
                        "current_config": $current_config,
                        "modes": []
                }]' <<<"${output}"
}

state1_json() {
        local current
        local resolution
        local refresh_rates
        local sub_output

        sub_output="$(jq '.[. | length - 1]' <<<"${output}")"

        if grep -Pq "\*" <<<"${line}"; then
                current="$(grep -Po "\d+\.\d+(?=\+?\*)" <<<"${line}")"
                sub_output="$(
                        jq \
                                --argjson current "${current}" \
                                '.current_config.refresh_rate = $current' \
                                <<<"${sub_output}"
                )"
        fi

        resolution="$(grep -Po "\d+x\S+" <<<"${line}")"
        refresh_rates="$(jq --null-input '[]')"
        for tmp in $(perl -pe "s/^\s+\w+\s+|\*|\+//g" <<<"${line}"); do
                refresh_rates="$(
                        jq \
                                --argjson rate "${tmp}" \
                                '. += [$rate]' <<<"${refresh_rates}"
                )"
        done

        sub_output="$(
                jq \
                        --arg resolution "${resolution}" \
                        --argjson refresh_rates "${refresh_rates}" \
                        '.modes += [{
                                "resolution": $resolution,
                                "refresh_rates": $refresh_rates
                        }]' <<<"${sub_output}"
        )"

        jq \
                --argjson sub_output "${sub_output}" \
                '.[. | length - 1] |= $sub_output' <<<"${output}"
}

main() {
        local output
        local state=0

        output="$(jq --null-input '[]')"

        local display_name
        while IFS=$'\n' read -r line; do
                if grep -Pq "^\w" <<<"${line}"; then
                        state=0
                        display_name="$(grep -Po "^\w+" <<<"${line}")"
                        if grep -q "VIRTUAL" <<<"${display_name}"; then
                                continue
                        fi
                        output="$(state0_json)"
                        state=1
                elif [[ "${state}" -eq 1 ]]; then
                        output="$(state1_json)"
                fi
        done <<<"$(xrandr --query | sed 1d)"

        echo "${output}"
}

main
