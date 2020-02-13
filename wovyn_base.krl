ruleset wovyn_base {

    meta {
        use module twilio_lesson_keys
        use module twilio_m alias twilio
            with account_sid = keys:twilio{"account_sid"}
                auth_token =  keys:twilio{"auth_token"}
    }

    global {
        temperature_threshold = 75.0
    }

    rule process_heartbeat {
        select when wovyn:heartbeat genericThing re#(.+)#
        pre {
            temp = event:attr("genericThing").get("data").get("temperature").head()

        }
        send_directive("test", {"hello": "world"})
        fired {
            raise wovyn event "new_temperature_reading"
                attributes {"temperature":temp.get("temperatureF"), "timestamp":time:now()}
        }
    }

    rule find_high_temps {
        select when wovyn:new_temperature_reading
        pre {
            temperature = event:attr("temperature")
            is_violation = (temperature > temperature_threshold) 
                => true | false
        }
        send_directive("temp_reading", {"is_violation": is_violation})
        fired {
            raise wovyn event "threshold_violation" 
                attributes {"temperature": temperature,"timestamp": event:attr("timestamp") , "threshold": temperature_threshold}
                if is_violation
        }
    }

    rule threshold_notification {
        select when wovyn:threshold_violation
        pre {
            message = "The current temperature of " + 
                event:attr("temperature") +
                " has violated the threshold of " +
                event:attr("threshold") +
                " at " +
                event:attr("timestamp") + 
                "."
        }
        // twilio:send_sms("+18013100486",
        //               "+12029911769",
        //               message)
    }

    //I hate changing the ruleset just to change the threshold so this seemed nice to have
    rule change_threshold {
        select when wovyn:new_threshold threshold re#(.+)#
        always {
            temperature_threshold = event:attr("threshold")
        }
    }
}