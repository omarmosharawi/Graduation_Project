# from django.test import TestCase

# Create your tests here.


import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_user_registration(client):
    url = reverse('SignUp-list')
    data = {
        "email": "test@example.com",
        "password": "StrongPassword@123!",
        "confirm_password": "StrongPassword@123!",
        "first_name": "Test",
        "last_name": "User",
        "phone": "1234567890",
        "accept_terms": True
    }
    response = client.post(url, data)
    assert response.status_code == 201
    assert "tokens" in response.data