from ssl import HAS_NEVER_CHECK_COMMON_NAME
from django.shortcuts import render
from django.http import HttpResponse
# Create your views here.

def index (response): 
    return HttpResponse("Hello, world. You are at the transactions index")