"use strict";

var OTRS = OTRS || {};
OTRS.Fred = OTRS.Fred || {};

/**
 * @namespace
 * @exports TargetNS as OTRS.Fred.HTMLCheck
 * @description
 *      This namespace contains all logic for the Fred module HTMLCHeck
 */
OTRS.Fred.HTMLCheck = (function (TargetNS) {

    var CheckFunctions = [];

    function HTMLEncode(Text){
        return Text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    }

    function OutputError($Element, ErrorType, ErrorDescription, Hint){

        // Get element HTML by wrapping it in a div and calling .html() on that
        var $Container = $('<div></div>');
        $Container.append( $Element.clone() );

        var Code = HTMLEncode($Container.html());

        var Message = $('<p class="Small"></p>');
        Message.append('<span class="Error">Error:</span> <strong>' + ErrorDescription + '</strong><div>' + Hint + '</div><div><code>' + Code + '</code></div>');
        $('#FredHTMLCheckResults').append(Message);
    }

    /**
     * @function
     * @description
     *      Performs various accessibility checks to see if the HTML code
     *      violates some of our guidelines.
     * @return
     *      nothing, but calls OutputError if an error was found
     */

    function CheckAccessibilityLabel() {
        $('input:text, input: password, input:checkbox, input:radio, select, textarea').each(function(){
            // first check if a title attribute is present, that is also ok for accessibility
            var Title = $(this).attr('title');
            if (Title && Title.length) return;

            // ok, no title available, now look for an assigned label element
            var Label = $('label[for=' + $(this).attr('id') + ']');
            if (!Label || !Label.length) {
                OutputError(
                    $(this),
                    'AccessibilityMissingLabel',
                    'Input element without a describing label or title attribute',
                    'Please add a title attribute or a label element with a "speaking" description for this element.'
                );
            }
            if (Label.length > 1) {
                OutputError(
                    $(this),
                    'AccessibilityMultipleLabel',
                    'Input element with more than one assigned labels',
                    'Please make sure that only one label is present for this input element.'
                );
            }
        });
    }
    CheckFunctions.push(CheckAccessibilityLabel);

    /**
     * @function
     * @description
     *      This function checks if HTMLCheck can be started (jQuery is loaded).
     * @return nothing.
     */
    TargetNS.CheckForStart = function () {
        if (jQuery) {
            $(document).ready(function(){
                OTRS.Fred.HTMLCheck.Run();
            });
        }
        else {
            setTimeout("OTRS.Fred.HTMLCheck.CheckForStart()", 250);
        }
    };

    /**
     * @function
     * @description
     *      Runs all available check functions
     * @return
     *      nothing
     */
    TargetNS.Run = function(){
        $.each(CheckFunctions, function(){
            this();
        });
    };

    return TargetNS;
}(OTRS.Fred.HTMLCheck || {}));