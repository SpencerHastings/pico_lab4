ruleset temperature_store {

    meta {
        provides threshold_violations, inrange_temperatures
        shares temperatures, threshold_violations, inrange_temperatures
    }

    global {
        temperatures = function() {
            ent:temps
        }

        threshold_violations = function() {
            ent:violations
        }

        inrange_temperatures = function() {
            ent:temps.difference(ent:violations)
        }

    }

    rule collect_temperatures {
        select when wovyn:new_temperature_reading

        always {
            ent:temps := ent:temps.append({"temperature":event:attr("temperature"), "timestamp":event:attr("timestamp")})
        }

    }

    rule collect_threshold_violations {
        select when wovyn:threshold_violation
        
        always {
            ent:violations := ent:violations.append({"temperature":event:attr("temperature"), "timestamp":event:attr("timestamp")})
        }

    }

    rule clear_temperatures {
        select when sensor:reading_reset
        always {    
            ent:temps := []
            ent:violations := []
        }
    }
}