Run the container as follows:

$docker run -itd -p some_port:8000 --name=container_name django

Eg- $docker run -itd -p 7000:8000 --name=test django

Now you can see it from browser with http://vm_ip:port

Or

If you have some app, then just mount that app folder,

$docker run -itd --v path_to _appr_on_vm:/root/my_project/your_app_name --name=container_name django

Do the needful changes (ref link: https://docs.djangoproject.com/en/1.10/intro/tutorial01/ )

Then you can just browse  it with http://vm_ip:port/your_app_name

For further development, attach to the container with 

$docker attach container_name

And start development.

