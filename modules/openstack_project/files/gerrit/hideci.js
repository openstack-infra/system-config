// Copyright (c) 2014 VMware, Inc.
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
var hashRegex = /^\#\/c\/[\/\d]+$/
// this regex matches CI comments
var ciRegex = / CI$/

window.onload = function() {
    var input = document.createElement("input");
    input.id = "toggleci";
    input.type = "button";
    input.className = "gwt-Button";
    input.value = "Toggle CI";
    input.onclick = function() {
        // CI comments in New Screen
        $("div").filter(function() {
            return ciRegex.test(this.innerHTML);
        }).parent().parent().parent().toggle();

        // CI comments in Old Screen
        $("div").filter(function() {
            return ciRegex.test(this.getAttribute('name'));
        }).toggle();
    }
    document.body.appendChild(input);
    if (!hashRegex.test(window.location.hash)) {
        $("#toggleci").hide();
    }
};

window.onhashchange = function() {
    if (hashRegex.test(window.location.hash)) {
        $("#toggleci").show();
    } else {
        $("#toggleci").hide();
    }
};
