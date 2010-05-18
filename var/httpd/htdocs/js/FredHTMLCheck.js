"use strict";

var OTRS = OTRS || {};
OTRS.Fred = OTRS.Fred || {};

/**
 * @namespace
 * @description
 *      This namespace contains all logic for the Fred module HTMLCHeck
 */
OTRS.Fred.HTMLCheck = (function () {
    function OutputError(ErrorType, ErrorDescription, $Element){

        // Get element HTML by wrapping it in a div and calling .html() on that
        var $Container = $('<div></div>');
        $Container.append( $Element.clone() );

        var Code = $Container.html().replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

        var Message = $('<p></p>');
        Message.append('Error: ' + ErrorType + ' (' + ErrorDescription + ') found in <code>' + Code + '</code>');
        $('#FredHTMLCheckResults').append(Message);
    }

    function CheckAccessibilityLabel() {
        $('input:text, input: password, input:checkbox, input:radio, select, textarea').each(function(){
            var Label = $('label[for=' + $(this).attr('id') + ']');
            if (!Label.length) {
                OutputError('MissingLabel', 'Input element without a describing label was detected', $(this));
            }
        });
    }

    return {
        /**
         * @function
         * @return nothing.
         * @description
         *      This function checks if HTMLCheck can be started (jQuery is loaded).
         */
        CheckForStart: function () {
            if (jQuery) {
                $(document).ready(function(){
                    OTRS.Fred.HTMLCheck.Run();
                });
            }
            else {
                setTimeout("OTRS.Fred.HTMLCheck.CheckForStart()", 250);
            }
        },

        Run: function(){
            CheckAccessibilityLabel();
        }
    };
}());