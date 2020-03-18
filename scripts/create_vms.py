import netaddr

from dcim.choices import InterfaceTypeChoices, InterfaceModeChoices
from dcim.models import Platform, DeviceRole, Site
from ipam.models import IPAddress, VRF, Interface, Prefix, VLAN
from tenancy.models import Tenant
from virtualization.models import VirtualMachine, Cluster
from virtualization.choices import VirtualMachineStatusChoices
from extras.scripts import Script, ObjectVar, ChoiceVar, TextVar, IntegerVar
from extras.models import Tag
from utilities.forms import APISelect


class DeployVM(Script):

    env = ""
    interfaces = []
    time_zone = ""
    dns_domain_private = ""
    dns_domain_public = ""
    dns_servers = []
    ntp_servers = []
    ssh_authorized_keys = []
    ssh_port = ""
    _default_interface = {}
    tags = []
    output = []
    success_log = ""

    class Meta:
        name = "Deploy new VMs"
        description = "Deploy new virtual machines from existing platforms and roles using AWX"
        fields = ['persist_disk', 'status', 'health_check', 'serial', 'tenant', 'cluster', 'env', 'untagged_vlan', 'backup', 'ip_addresses', 'vm_count', 'vcpus', 'memory', 'platform', 'role', 'disk', 'ssh_authorized_keys', 'hostnames']
        field_order = ['status', 'tenant', 'cluster', 'env', 'platform', 'role', 'health_check', 'serial', 'persist_disk', 'backup', 'vm_count', 'vcpus', 'memory', 'disk', 'hostnames', 'untagged_vlan', 'ip_addresses', 'ssh_authorized_keys']
        commit_default = False

    health_check = ChoiceVar(
        label="Health checks on deployment",
        description="Deployment will fail if server does not pass Consul health checks",
        required=True,
        choices=(
            ('True', 'Yes'),
            ('False', 'No')
        )
    )

    serial = ChoiceVar(
        label="Serial deployment",
        description="VM will not be parallelized in deployment",
        required=True,
        choices=(
            ('False', 'No'),
            ('True', 'Yes'),
        )
    )

    persist_disk = ChoiceVar(
        label="Persist volume on redeploy",
        description="VM will persist disk2 in vSphere on redeploys",
        required=True,
        choices=(
            ('False', 'No'),
            ('True', 'Yes'),
        )
    )

    status = ChoiceVar(
        label="VM Status",
        description="Deploy VM now or later?",
        required=True,
        choices=(
            (VirtualMachineStatusChoices.STATUS_STAGED, 'Staged (Deploy now)'),
            (VirtualMachineStatusChoices.STATUS_PLANNED, 'Planned (Save for later)')
        )
    )

    tenant = ObjectVar(
        default="patientsky-hosting",
        description="Name of the tenant the VMs beloing to",
        queryset=Tenant.objects.filter()
    )

    cluster = ObjectVar(
        default="odn1",
        description="Name of the vSphere cluster you are deploying to",
        queryset=Cluster.objects.all()
    )

    env = ChoiceVar(
        label="Environment",
        description="Environment to deploy VM",
        default="vlb",
        choices=(
            ('pno', 'pno'),
            ('inf', 'inf'),
            ('stg', 'stg'),
            ('dev', 'dev'),
            ('hem', 'hem'),
            ('hov', 'hov'),
            ('hpl', 'hpl'),
            ('mgt', 'mgt'),
            ('cse', 'cse'),
            ('qua', 'qua'),
            ('dmo', 'dmo'),
            ('vlb', 'vlb'),
            ('cmi', 'cmi')
        )
    )

    platform = ObjectVar(
        description="Host OS to deploy",
        queryset=Platform.objects.filter(
            name__regex=r'^(base_.*)'
        ).order_by('name')
    )

    role = ObjectVar(
        label="VM Role",
        description="VM Role",
        queryset=DeviceRole.objects.filter(
            vm_role=True
        ).order_by('name')
    )

    backup = ChoiceVar(
        label="Backup strategy",
        description="The backup strategy deployed to this VM with Veeam",
        required=True,
        choices=(
            ('nobackup', 'Never'),
            ('backup_general_1', 'Daily'),
            ('backup_general_4', 'Monthly')
        )
    )

    ip_addresses = TextVar(
        required=False,
        label="IP Addresses",
        description="List of IP addresses to create w. prefix e.g 192.168.0.10/24. If none given, hosts will be assigned IPs 'automagically'"
    )

    untagged_vlan = ObjectVar(
        required=False,
        label="VLAN",
        widget=APISelect(api_url='/api/ipam/vlans/', display_field='display_name'),
        queryset=VLAN.objects.all(),
        description="Choose VLAN for IP-addresses",
    )

    hostnames = TextVar(
        required=True,
        label="Hostnames",
        description="List of hostnames to create."
    )

    ssh_authorized_keys = TextVar(
        label="SSH Authorized Keys",
        required=False,
        description="List of accepted SSH keys - defaults to site config context 'ssh_authorized_keys'"
    )

    vm_count = ChoiceVar(
        label="Number of VMs",
        description="Number of VMs to deploy",
        choices=(
            ('1', '1'),
            ('2', '2'),
            ('3', '3'),
            ('4', '4'),
            ('5', '5'),
            ('6', '6'),
            ('7', '7'),
            ('8', '8'),
            ('9', '9'),
            ('10', '10')
        )
    )

    vcpus = ChoiceVar(
        label="Number of CPUs",
        description="Number of virtual CPUs",
        default="2",
        choices=(
            ('1', '1'),
            ('2', '2'),
            ('3', '3'),
            ('4', '4'),
            ('5', '5'),
            ('6', '6'),
            ('7', '7'),
            ('8', '8')
        )
    )

    memory = ChoiceVar(
        description="Amount of VM memory",
        default="4096",
        choices=(
            ('1024', '1024'),
            ('2048', '2048'),
            ('4096', '4096'),
            ('8192', '8192'),
            ('16384', '16384'),
            ('32768', '32768')
        )
    )

    disk = IntegerVar(
        label="Disk size",
        description="Disk size in GB",
        default="20"
    )

    def appendLogSuccess(self, log: str, obj=None):
        self.success_log += " {} `\n{}\n`".format(log, obj)
        return self

    def flushLogSuccess(self):
        self.log_success(self.success_log)
        self.success_log = ""
        return self

    def _generateHostname(self, cluster, env, descriptor):

        # I now proclaim this VM, First of its Name, Queen of the Andals and the First Men, Protector of the Seven Kingdoms
        vm_index = "001"

        search_for = str(cluster) + '-' + env + '-' + descriptor + '-'
        vms = VirtualMachine.objects.filter(
            name__startswith=search_for
        )

        if len(vms) > 0:
            # Get last of its kind
            last_vm_index = int(vms[len(vms) - 1].name.split('-')[3]) + 1
            if last_vm_index < 10:
                vm_index = '00' + str(last_vm_index)
            elif last_vm_index < 100:
                vm_index = '0' + str(last_vm_index)
            else:
                vm_index = str(last_vm_index)

        hostname = str(cluster) + '-' + env + '-' + descriptor + '-' + vm_index

        return hostname

    def __validateInput(self, data, base_context_data):

        try:
            self.interfaces = base_context_data['interfaces']
            self.time_zone = base_context_data['time_zone']
            self.tags = base_context_data['tags']
            self.dns_domain_private = base_context_data['dns_domain_private']
            self.dns_domain_public = base_context_data['dns_domain_public']
            self.dns_servers = base_context_data['dns_servers']
            self.ntp_servers = base_context_data['ntp_servers']
            self.ssh_authorized_keys = base_context_data['ssh_authorized_keys']
            self.ssh_port = base_context_data['ssh_port']
            self.tags.update({'env_' + self.env: {'comments': 'Environment', 'color': '009688'}})
            self.tags.update({'vsphere_' + data['backup']: {'comments': 'Backup strategy', 'color': '009688'}})
            if (data['health_check'] == 'True'):
                self.tags.update({'health_check': {'comments': 'Do health checks in deployment', 'color': '4caf50'}})
            if (data['serial'] == 'True'):
                self.tags.update({'serial': {'comments': 'Do health checks in deployment', 'color': '4caf50'}})
        except Exception as error:
            self.log_failure("Error when parsing context_data! Error: " + str(error))
            return False

        if self.interfaces is None:
            self.log_failure("No interfaces object in context data!")
            return False

        if data['ip_addresses'] != "" and len(data['ip_addresses'].splitlines()) != int(data['vm_count']):
            self.log_failure("The number of IP addresses and VMs does not match!")
            return False

        if data['hostnames'] != "" and len(data['hostnames'].splitlines()) != int(data['vm_count']):
            self.log_failure("The number of hostnames and VMs does not match!")
            return False

        if self.interfaces is None:
            self.log_failure("No interfaces object in context data!")
            return False

        return True

    def run(self, data):

        vrf = VRF.objects.get(
            name="global"
        )

        self.env = data['env']

        # Setup base virtual machine for copying config_context
        base_vm = VirtualMachine(
            cluster=data['cluster'],
            platform=data['platform'],
            role=data['role'],
            tenant=data['tenant'],
            name="script_temp"
        )

        base_vm.save()

        if self.__validateInput(data=data, base_context_data=base_vm.get_config_context()) is False:
            return False

        # Delete base virtual machine for copying config_context
        vm_delete = VirtualMachine.objects.get(
            name="script_temp"
        )
        vm_delete.delete()

        for i in range(0, int(data['vm_count'])):

            hostnames = data['hostnames'].splitlines()
            ip_addresses = data['ip_addresses'].splitlines()

            if len(hostnames) > 0:
                hostname = hostnames[i]
            else:
                hostname = self._generateHostname(
                    cluster=data['cluster'].name,
                    env=self.env,
                    descriptor="na"
                )

            # Check if VM exists
            if len(VirtualMachine.objects.filter(name=hostname)) > 0:
                self.log_failure("VM with hostname " + hostname + " already exists!")
                return False

            if len(ip_addresses) > 0:

                # Check if IP address exists
                ip_check = IPAddress.objects.filter(
                    address=ip_addresses[i]
                )

                if len(ip_check) > 0:
                    self.log_failure(str(ip_check[0].address) + ' is already assigned to ' + str(ip_check[0].interface.name))
                    return False

                domain = self.dns_domain_private if netaddr.IPNetwork(ip_addresses[i]).is_private() is True else self.dns_domain_public
                ip_address = IPAddress(
                    address=ip_addresses[i],
                    vrf=vrf,
                    tenant=data['tenant'],
                    family=4,
                    dns_name=hostname + '.' + domain,
                )

                ip_address.save()
                self.appendLogSuccess(log="Created IP", obj=ip_addresses[i]).appendLogSuccess(log="DNS", obj=hostname + '.' + domain)
            else:
                if data['untagged_vlan'] is not None:

                    try:

                        # Auto assign IPs from vsphere_port_group
                        prefix = Prefix.objects.get(
                            vlan=data['untagged_vlan'],
                            site=Site.objects.get(name=data['cluster'].site.name),
                            is_pool=True
                        )

                        ip = prefix.get_first_available_ip()

                        domain = self.dns_domain_private if netaddr.IPNetwork(ip).is_private() is True else self.dns_domain_public
                        ip_address = IPAddress(
                            address=ip,
                            vrf=vrf,
                            tenant=data['tenant'],
                            family=4,
                            dns_name=hostname + '.' + domain,
                        )

                        ip_address.save()
                        self.appendLogSuccess(log="Auto-assigned IP", obj=ip).appendLogSuccess(log="DNS", obj=hostname + '.' + domain)
                    except Exception:
                        self.log_failure("An error occurred while auto-assigning IP address. VLAN or Prefix not found!")
                        return False
                else:
                    self.log_failure("No IP address choice was made")
                    return False

            vm = VirtualMachine(
                status=data['status'],
                cluster=data['cluster'],
                platform=data['platform'],
                role=data['role'],
                tenant=data['tenant'],
                name=hostname,
                disk=data['disk'],
                memory=data['memory'],
                vcpus=data['vcpus']
            )

            vm.primary_ip4 = ip_address
            vm.save()
            self.appendLogSuccess(log="for VM in ", obj=vm.cluster)

            self.__assignTags(vm=vm)

            # Assign IP to interface
            if self.__setupInterface(ip_address=ip_address, data=data, vm=vm) is False:
                return False

            self.flushLogSuccess()

        return self.success_log

    def __assignTags(self, vm: VirtualMachine):
        """
        Assign tags from context data
        """
        for tag in self.tags:
            if len(Tag.objects.filter(name=tag)) == 0:
                color = self.tags[tag]['color'] if 'color' in self.tags[tag] else '9e9e9e'
                comments = self.tags[tag]['comments'] if 'comments' in self.tags[tag] else 'No comments'
                newTag = Tag(comments=comments, name=tag, color=color)
                newTag.save()

            vm.tags.add(tag)

        vm.save()

    def __setupInterface(self, ip_address: IPAddress, vm: VirtualMachine, data):
        """
        Setup interface and add IP address
        """

        # Get net address tools
        ip = netaddr.IPNetwork(ip_address.address)
        prefix_search = str(ip.network) + '/' + str(ip.prefixlen)

        try:
            prefix = Prefix.objects.get(
                prefix=prefix_search,
                is_pool=True
            )
        except Exception:
            self.log_failure("Prefix for IP " + ip_address.address + " was not found")
            return False

        # Right now we dont support multiple nics. But the data model supports it
        interface = Interface(
            name=self.interfaces['nic0']['name'],
            mtu=self.interfaces['nic0']['mtu'],
            virtual_machine=vm,
            type=InterfaceTypeChoices.TYPE_VIRTUAL
        )

        # If we need anything other than Access, here is were to change it
        if self.interfaces['nic0']['mode'] == "Access":
            interface.mode = InterfaceModeChoices.MODE_ACCESS
            interface.untagged_vlan = prefix.vlan
            self.interfaces['nic0']['vsphere_port_group'] = prefix.vlan.name

        interface.save()

        # Add interface to IP address
        ip_address.interface = interface
        ip_address.save()

        self.appendLogSuccess(log="with interface ", obj=interface).appendLogSuccess(log=", vlan ", obj=prefix.vlan.name)

        return True
