package com.it_nomads.flutter_realm_example;

import io.realm.RealmObject;
import io.realm.annotations.Required;
import io.realm.annotations.PrimaryKey;

public class Product extends RealmObject  {
    @PrimaryKey
    @Required
    private String uuid;
    private String title;
}
