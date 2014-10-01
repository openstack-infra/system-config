// Copyright (c) 2014 VMware, Inc.
// Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

// this regex matches the hash part of review pages
var hashRegex = /^\#\/c\/[\/\d]+$/;
// this regex matches CI comments
var ciRegex = /^(.* CI|Jenkins)$/;
// this regex matches "Patch set #"
var psRegex = /^<p>(Uploaded patch set|Patch Set) (\d+)(:|\.)/;
// this regex matches merge failure messages
var mergeFailedRegex = /Merge Failed\./;
// this regex matches the name of CI systems we trust to report merge failures
var trustedCIRegex = /^(OpenStack CI|Jenkins)$/;

var ci_parse_psnum = function($panel) {
    var match = psRegex.exec($panel.html());
    if (match !== null) {
        return parseInt(match[2]);
    }
    return 0;
};

var ci_parse_is_merge_conflict = function($panel) {
    return (mergeFailedRegex.exec($panel.html()) !== null);
};

var ci_parse_results = function($panel) {
    var result_list = [];
    var test_results = $panel.find("li.comment_test");
    if (test_results !== null) {
        test_results.each(function(i, li) {
            var result = {};
            result["name"] = $(li).find("span.comment_test_name").find("a")[0].innerHTML;
            result["link"] = $(li).find("span.comment_test_name").find("a")[0];
            result["result"] = $(li).find("span.comment_test_result")[0];
            result_list.push(result);
        });
    }
    return result_list;
};

var ci_parse_comments = function() {
    var comments = [];
    $(".commentPanel").each(function() {
        var comment = {};
        comment.name = $(this).attr("name");
        comment.email = $(this).attr("email");
        comment.date = $(this).find(".commentPanelDateCell").attr("title");
        var comment_panel = $(this).find(".commentPanelMessage");
        comment.psnum = ci_parse_psnum(comment_panel);
        comment.merge_conflict = ci_parse_is_merge_conflict(comment_panel);
        comment.results = ci_parse_results(comment_panel);
        comment.is_ci = (ciRegex.exec(comment.name) !== null);
        comment.is_trusted_ci = (trustedCIRegex.exec(comment.name) !== null);
        comment.ref = this;
        comments.push(comment);
    });
    return comments;
};

var ci_latest_patchset = function(comments) {
    var psnum = 0;
    for (var i = 0; i < comments.length; i++) {
        psnum = Math.max(psnum, comments[i].psnum);
    }
    return psnum;
};

var ci_is_merge_conflict = function(comments) {
    var latest = ci_latest_patchset(comments);
    var conflict = false;
    for (var i = 0; i < comments.length; i++) {
        var comment = comments[i];
        // only if we are actually talking about the latest patch set
        if (comment.psnum == latest) {
            if (comment.is_trusted_ci) {
                conflict = comment.merge_conflict;
            }
        }
    }
    return conflict;
};

var ci_prepare_results_table = function() {
    // Create a table and insert it after the approval table
    var table = $("table.test_result_table")[0];
    if (!table) {
        table = document.createElement("table");
        $(table).addClass("test_result_table");
        $(table).addClass("infoTable").css({"margin-top":"1em", "margin-bottom":"1em"});
        var approval_table = $("div.approvalTable");
        if (approval_table.length) {
            var outer_table = document.createElement("table");
            $(outer_table).insertBefore(approval_table);
            var outer_table_row = document.createElement("tr");
            $(outer_table).append(outer_table_row);
            var td = document.createElement("td");
            $(outer_table_row).append(td);
            $(td).css({"vertical-align":"top"});
            $(td).append(approval_table);
            td = document.createElement("td");
            $(outer_table_row).append(td);
            $(td).css({"vertical-align":"top"});
            $(td).append(table);
        } else {
            var big_table_row = $("div.screen>div>div>table>tbody>tr");
            var td = $(big_table_row).children()[1];
            $(td).append(table);
        }
    } else {
        $(table).empty();
    }
    return table;
};

var ci_display_results = function(comments) {
    var table = ci_prepare_results_table();
    if (ci_is_merge_conflict(comments)) {
        var mc_header = $("<tr>").append($('<td class="merge_conflict" colpsan="2">Patch in Merge Conflict</td>'));
        mc_header.css('width', '400');
        mc_header.css('font-weight', 'bold');
        mc_header.css('color', 'red');
        mc_header.css('padding-left', '2em');
        $(table).append(mc_header);

        return;
    }
    var current = ci_latest_patchset(comments);
    for (var i = 0; i < comments.length; i++) {
        var comment = comments[i];
        if ((comment.psnum == current) && comment.is_ci && (comment.results.length > 0)) {
            var header = $("<tr>").append($('<td class="header">' + comment.name + '</td>'));
            header.append('<td class="header ci_date">' + comment.date + '</td>');
            $(table).append(header);

            for (var j = 0; j < comment.results.length; j++) {
                var result = comment.results[j];
                var tr = $("<tr>");
                tr.append($("<td>").append($(result["link"]).clone()));
                tr.append($("<td>").append($(result["result"]).clone()));
                $(table).append(tr);
            }
        }
    }
};

var ci_toggle_visibility = function(comments) {
    if (!comments) {
        comments = ci_parse_comments();
    }
    $.each(comments, function(i, comment) {
        if (comment.is_ci) {
            $(comment.ref).toggle();
        }
    });
};

var ci_hide_ci_comments = function(comments) {
    if (!comments) {
        comments = ci_parse_comments();
    }
    $.each(comments, function(i, comment) {
        if (comment.is_ci) {
            $(comment.ref).hide();
        }
    });
};

var ci_page_loaded = function() {
    if (hashRegex.test(window.location.hash)) {
        $("#toggleci").show();
        var comments = ci_parse_comments();
        ci_display_results(comments);
        ci_hide_ci_comments(comments);
    } else {
        $("#toggleci").hide();
    }
};


window.onload = function() {
    var input = document.createElement("input");
    input.id = "toggleci";
    input.type = "button";
    input.className = "gwt-Button";
    input.value = "Toggle CI";
    input.onclick = function() { ci_toggle_visibility(null); };
    document.body.appendChild(input);

    MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
    var observer = new MutationObserver(function(mutations, observer) {
        var span = $("span.rpcStatus");
        $.each(mutations, function(i, mutation) {
            if (mutation.target === span[0] &&
                mutation.attributeName === "style" &&
                (!(span.is(":visible:")))) {
                ci_page_loaded();
            }
        });
    });
    observer.observe(document, {
        subtree: true,
        attributes: true
    });
};
