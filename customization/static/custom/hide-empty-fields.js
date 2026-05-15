document.addEventListener("DOMContentLoaded", function () {

    document.querySelectorAll("tr").forEach(function (row) {

        const cells = row.querySelectorAll("td");

        if (cells.length >= 2) {

            const value = cells[cells.length - 1].innerText.trim();

            if (
                value === "—" ||
                value === "-" ||
                value === ""
            ) {
                row.style.display = "none";
            }

        }

    });

});
