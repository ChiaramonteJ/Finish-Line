document.addEventListener("DOMContentLoaded", function () {
    function loadComponent(placeholderId, componentPath, errorLabel) {
        var placeholder = document.getElementById(placeholderId);
        if (!placeholder) return Promise.resolve();

        return fetch(componentPath)
            .then(function (response) {
                return response.text();
            })
            .then(function (data) {
                placeholder.innerHTML = data;
            })
            .catch(function (error) {
                console.error(errorLabel + " load error:", error);
            });
    }

    Promise.all([
        loadComponent("navbar-placeholder", "/components/navbar.html", "Navbar"),
        loadComponent("footer-placeholder", "/components/footer.html", "Footer")
    ]).then(function () {
        var yearEl = document.getElementById("footer-year");
        if (yearEl) yearEl.textContent = new Date().getFullYear();
    });
});
