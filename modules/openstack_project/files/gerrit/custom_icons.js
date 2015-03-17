// Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
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

var replace_wip_icon = function() {
    var deny_image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAo0lEQVR42mNgGPrg8+7d/191dPwnWePPu3f/XxEUBGNk8bczZ/6/yMAAFgepwWkrSBEIw2x/Vl4OFwPhB6GhuF11XUkJrvBxWhqcDbIV5AK8Tv925gxYIbJtt4yN//959464cAA5GVkzQRux+RsZ33Vx+f9h1ar/RNkIcjrICyBNyIaAwgTDCyB/IStCjmuQs0GGgTSCDMSwFWQazBayEgndAQAqW6dvdnJ0RwAAAABJRU5ErkJggg==';
    var tds = document.getElementsByClassName('dataCell cAPPROVAL singleLine');
    for (var i = 0; i < tds.length; i++) {
        var title = tds[i].title;
        if (title.indexOf("Workflow") > -1) {
            var images = tds[i].getElementsByTagName('img');
            for (var j = 0; j < images.length; j++) {
                if (images[j].src.indexOf(deny_image) !== -1) {
                    images[j].src = images[j].src.replace(deny_image, "static/wip.png");
                }
            }
        }
    }
};
