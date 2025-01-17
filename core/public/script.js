window.addEventListener('DOMContentLoaded',function () {


    apps = document.getElementsByClassName('application-link');
    for (var i = 0; i < apps.length; i++) {
        apps[i].addEventListener('click', function(e){
            // Hide all content.
            content = document.getElementsByClassName('content');
            for (var k = 0; k < content.length; k++) {
                content[k].style.display = 'none';
            }
            // Show the content we want.
            document.getElementById('services-' + e.target.dataset.app).style.display = 'block';
        }, false);
    }

    // Go directly to an application if we specify it in the url.
    var hash = window.location.hash;
    if (hash.length > 0) {
        hash = hash.substring(1);
        const el = document.getElementById('application-link-' + hash);
        if (el !== null) {
            el.click();
        }
    }

});