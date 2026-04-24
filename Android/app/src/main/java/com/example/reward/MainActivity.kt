package com.example.reward

import ForgotPasswordScreen
import LoginScreen
import MapScreen


import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.reward.data.Composables.homeHeader
import com.example.reward.data.Composables.reHeader

import com.example.reward.ui.theme.Screens.HomeScreen

import com.example.reward.ui.theme.Screens.SignUpScreen
import com.example.reward.ui.theme.Screens.editprofilescreen
import com.example.reward.ui.theme.Screens.locationscreen
import com.example.reward.ui.theme.Screens.newpasswordscreen
import com.example.reward.ui.theme.Screens.pickupscreen
import com.example.reward.ui.theme.Screens.qrscreen

import org.osmdroid.config.Configuration


class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        Configuration.getInstance().load(this, getSharedPreferences("osm", MODE_PRIVATE))
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
          // LoginScreen()
            // SignUpScreen()
            // reHeaderLogo()
            // reHeader()
            // HomeHeader()
            // homeHeader()
          // HomeScreen()
           //MapScreen()
           //editprofilescreen()
            //pickupscreen()
          //  locationscreen()
                //ForgotPasswordScreen()
           // newpasswordscreen()
            qrscreen()
        }

    }
}
