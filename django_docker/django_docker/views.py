from django.http import render

def hello_world(request):
    return render(request, 'hello_world/index.html')
