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

    function CheckAccessibility() {
        /*
         * check if input elements either have a label or an assigned title text
         */
        $('input:text, input: password, input:checkbox, input:radio, select, textarea').each(function(){
            var $this = $(this),
                Label = $([]);

            if ($this.attr('id') && $this.attr('id').length) {
                Label = $('label[for=' + $this.attr('id')  + ']');
            }

            if (Label.length > 1) {
                OutputError(
                    $this,
                    'AccessibilityMultipleLabel',
                    'Input element with more than one assigned labels',
                    'Please make sure that only one label is present for this input element.'
                );
            }

            // first check if a title attribute is present, that is also ok for accessibility
            var Title = $this.attr('title');
            if (Title && Title.length) {
                return;
            }

            // ok, no title available, now look for an assigned label element
            if (!Label || !Label.length) {
                OutputError(
                    $this,
                    'AccessibilityMissingLabel',
                    'Input element without a describing label or title attribute',
                    'Please add a title attribute or a label element with a "speaking" description for this element.'
                );
            }
        });

        /*
         * check if links have either a text or a title
         */
        $('a').each(function(){
            var $this = $(this);

            if ($this.attr('name') && !$this.attr('href')) {
                return;
            }

            if ($this.text() && $this.text().length) {
                return;
            }
            if ($this.attr('title') && $this.attr('title').length) {
                return;
            }

            OutputError(
                $this,
                'AccessibilityInaccessibleLink',
                'Link without text or title',
                'Please make sure that every link has either a text content or a title attribute that can be used by a screenreader to identify the link.'
            );

        });
    }
    CheckFunctions.push(CheckAccessibility);

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
        if ($('#FredHTMLCheckResults').text() === '') {
            $('#FredHTMLCheckResults').html('<p class="Confirmation">All checks ok.</p>');
        }
    };

    return TargetNS;
}(OTRS.Fred.HTMLCheck || {}));