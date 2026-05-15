from setuptools import setup, find_packages

setup(
    name='netbox_hide_fields',
    version='0.1',
    description='Hide empty fields in NetBox',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
)
