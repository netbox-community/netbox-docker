from extras.plugins import PluginTemplateExtension


class DeviceEmptyFieldsHider(PluginTemplateExtension):
    model = 'dcim.device'

    def right_page(self):
        return """
<script>
document.addEventListener("DOMContentLoaded", function() {

    document.querySelectorAll("tr").forEach(function(row){

        let cells=row.querySelectorAll("td");

        if(cells.length>=2){

            let value=cells[1].innerText.trim();

            if(value==="—" || value==="-"){
                row.style.display="none";
            }

        }

    });

});
</script>
"""


template_extensions = [DeviceEmptyFieldsHider]
