package com.it_nomads.flutter_realm;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.realm.DynamicRealm;
import io.realm.DynamicRealmObject;
import io.realm.OrderedCollectionChangeSet;
import io.realm.OrderedRealmCollectionChangeListener;
import io.realm.Realm;
import io.realm.RealmConfiguration;
import io.realm.RealmFieldType;
import io.realm.RealmList;
import io.realm.RealmQuery;
import io.realm.RealmResults;

class FlutterRealm {
    private final String realmId;
    private DynamicRealm realm;
    private HashMap<String, RealmResults> subscriptions = new HashMap<>();
    private final MethodChannel channel;

    FlutterRealm(MethodChannel channel, String realmId, Map arguments) {
        this.channel = channel;
        this.realmId = realmId;

        RealmConfiguration.Builder builder = new RealmConfiguration.Builder().modules(Realm.getDefaultModule());

        String inMemoryIdentifier = (String) arguments.get("inMemoryIdentifier");

        if (inMemoryIdentifier == null) {
        } else {
            builder.inMemory().name(inMemoryIdentifier);
        }
        RealmConfiguration config = builder.build();

        Realm.getInstance(config);
        realm = DynamicRealm.getInstance(config);
    }

    FlutterRealm(MethodChannel channel, String realmId, RealmConfiguration configuration) {
        this.channel = channel;
        this.realmId = realmId;
        Realm.getInstance(configuration);
        realm = DynamicRealm.getInstance(configuration);
    }

    FlutterRealm(MethodChannel channel, String realmId, Realm realm) {
        this.channel = channel;
        this.realmId = realmId;
        this.realm =
                DynamicRealm.getInstance(realm.getConfiguration());

    }

    void onMethodCall(MethodCall call, MethodChannel.Result result) {

        try {
            Map arguments = (Map) call.arguments;
            switch (call.method) {
                case "createObject": {
                    String className = (String) arguments.get("$");
                    final String uuid = (String) arguments.get("uuid");


                    assert className != null;
                    assert uuid != null;

                    realm.beginTransaction();
                    DynamicRealmObject object = realm.createObject(className, uuid);
                    mapToObject(object, arguments);
                    realm.commitTransaction();

                    result.success(null);
                    break;
                }
                case "deleteObject": {
                    String className = (String) arguments.get("$");
                    Object primaryKey = arguments.get("primaryKey");


                    DynamicRealmObject object = find(className, primaryKey);
                    realm.beginTransaction();
                    object.deleteFromRealm();
                    realm.commitTransaction();

                    result.success(null);
                    break;
                }
                case "allObjects": {
                    String className = (String) arguments.get("$");
                    RealmResults<DynamicRealmObject> results = realm.where(className).findAll();
                    List list = convert(results);
                    result.success(list);
                    break;
                }
                case "updateObject": {
                    String className = (String) arguments.get("$");
                    Object primaryKey = arguments.get("primaryKey");
                    HashMap value = (HashMap) arguments.get("value");

                    DynamicRealmObject object = find(className, primaryKey);

                    if (object == null) {
                        String msg = String.format("%s not found with primaryKey = %s", className, primaryKey);
                        result.error(msg, null, null);
                        return;
                    }

                    realm.beginTransaction();
                    mapToObject(object, value);
                    realm.commitTransaction();

                    result.success(objectToMap(object));
                    break;
                }
                case "subscribeAllObjects": {
                    String className = (String) arguments.get("$");
                    String subscriptionId = (String) arguments.get("subscriptionId");

                    RealmResults<DynamicRealmObject> subscription = realm.where(className).findAllAsync();
                    subscribe(subscriptionId, subscription);

                    result.success(null);
                    break;
                }
                case "subscribeObjects": {
                    String className = (String) arguments.get("$");
                    String subscriptionId = (String) arguments.get("subscriptionId");
                    List predicate = (List) arguments.get("predicate");

                    RealmResults<DynamicRealmObject> subscription = getQuery(realm.where(className), predicate).findAllAsync();
                    subscribe(subscriptionId, subscription);

                    result.success(null);
                    break;
                }
                case "objects": {
                    String className = (String) arguments.get("$");
                    List predicate = (List) arguments.get("predicate");


                    RealmResults<DynamicRealmObject> results = getQuery(realm.where(className), predicate).findAll();
                    List list = convert(results);
                    result.success(list);
                    break;
                }
                case "unsubscribe": {
                    String subscriptionId = (String) arguments.get("subscriptionId");
                    if (subscriptionId == null) {
                        throw new Exception("No argument: subscriptionId");
                    }

                    if (!subscriptions.containsKey(subscriptionId)) {
                        throw new Exception("Not subscribed: " + subscriptionId);
                    }
                    RealmResults subscription = subscriptions.remove(subscriptionId);
                    if (subscription != null) {
                        subscription.removeAllChangeListeners();
                    }

                    result.success(null);
                    break;
                }
                case "deleteAllObjects": {
                    this.realm.beginTransaction();
                    this.realm.deleteAll();
                    this.realm.commitTransaction();

                    result.success(null);
                    break;
                }
                case "filePath": {
                    result.success(realm.getConfiguration().getPath());
                    break;
                }
                default:
                    result.notImplemented();
                    break;
            }

        } catch (Exception e) {
            if (realm.isInTransaction()) {
                realm.cancelTransaction();
            }
            e.printStackTrace();
            result.error(e.getMessage(), e.getMessage(), e.getStackTrace().toString());
        }
    }

    private DynamicRealmObject find(String className, Object primaryKey) {
        DynamicRealmObject object = null;
        if (primaryKey instanceof String) {
            object = realm.where(className).equalTo("uuid", (String) primaryKey).findFirst();
        } else if (primaryKey instanceof Integer) {
            object = realm.where(className).equalTo("uuid", (Integer) primaryKey).findFirst();
        }
        return object;
    }

    private RealmQuery<DynamicRealmObject> getQuery(RealmQuery<DynamicRealmObject> query, List<List> predicate) throws Exception {
        if (predicate == null) {
            return query;
        }
        RealmQuery<DynamicRealmObject> result = query;

        for (List item : predicate) {
            String operator = (String) item.get(0);

            switch (operator) {
                case "greaterThan": {
                    String fieldName = (String) item.get(1);
                    Object argument = item.get(2);
                    if (argument instanceof Integer) {
                        result = result.greaterThan(fieldName, (Integer) argument);
                    } else if (argument instanceof Long) {
                        result = result.greaterThan(fieldName, (Long) argument);
                    } else {
                        throw new Exception("Unsupported type");

                    }
                }
                break;
                case "greaterThanOrEqualTo": {
                    String fieldName = (String) item.get(1);
                    Object argument = item.get(2);
                    if (argument instanceof Integer) {
                        result = result.greaterThanOrEqualTo(fieldName, (Integer) argument);
                    } else if (argument instanceof Long) {
                        result = result.greaterThanOrEqualTo(fieldName, (Long) argument);
                    } else {
                        throw new Exception("Unsupported type");
                    }
                }
                break;
                case "lessThan": {
                    String fieldName = (String) item.get(1);
                    Object argument = item.get(2);
                    if (argument instanceof Integer) {
                        result = result.lessThan(fieldName, (Integer) argument);
                    } else if (argument instanceof Long) {
                        result = result.lessThan(fieldName, (Long) argument);
                    } else {
                        throw new Exception("Unsupported type");

                    }
                }
                break;
                case "lessThanOrEqualTo": {
                    String fieldName = (String) item.get(1);
                    Object argument = item.get(2);
                    if (argument instanceof Integer) {
                        result = result.lessThanOrEqualTo(fieldName, (Integer) argument);
                    } else if (argument instanceof Long) {
                        result = result.lessThanOrEqualTo(fieldName, (Long) argument);
                    } else {
                        throw new Exception("Unsupported type");
                    }
                }
                break;
                case "equalTo": {
                    String fieldName = (String) item.get(1);
                    Object argument = item.get(2);
                    if (argument instanceof Integer) {
                        result = result.equalTo(fieldName, (Integer) argument);
                    } else if (argument instanceof String) {
                        result = result.equalTo(fieldName, (String) argument);
                    } else if (argument instanceof Long) {
                        result = result.equalTo(fieldName, (Long) argument);
                    } else {
                        throw new Exception("Unsupported type");
                    }
                }
                break;
                case "notEqualTo": {
                    String fieldName = (String) item.get(1);
                    Object argument = item.get(2);
                    if (argument instanceof Integer) {
                        result = result.notEqualTo(fieldName, (Integer) argument);
                    } else if (argument instanceof String) {
                        result = result.equalTo(fieldName, (String) argument);
                    } else if (argument instanceof Long) {
                        result = result.equalTo(fieldName, (Long) argument);
                    } else {
                        throw new Exception("Unsupported type");
                    }
                }
                break;
                case "contains": {
                    String fieldName = (String) item.get(1);
                    Object argument = item.get(2);
                    if (argument instanceof String) {
                        result = result.contains(fieldName, (String) argument);
                    } else {
                        throw new Exception("Unsupported type");
                    }
                }
                break;
                case "and":
                    result = result.and();
                    break;
                case "or":
                    result = result.or();
                    break;
                default:
                    throw new Exception("Unknown operator");
            }
        }
        return result;
    }

    private void subscribe(final String subscriptionId, RealmResults<DynamicRealmObject> subscription) throws Exception {
        if (subscriptions.containsKey(subscriptionId)) {
            throw new Exception("Already subscribed");
        }

        subscriptions.put(subscriptionId, subscription);
        subscription.addChangeListener(new OrderedRealmCollectionChangeListener<RealmResults<DynamicRealmObject>>() {
            @Override
            public void onChange(RealmResults<DynamicRealmObject> results, OrderedCollectionChangeSet changeSet) {
                List list = convert(results);
                Map<String, Object> map = new HashMap<>();
                map.put("realmId", realmId);
                map.put("subscriptionId", subscriptionId);
                map.put("results", list);

                channel.invokeMethod("onResultsChange", Collections.unmodifiableMap(map));
            }
        });
    }

    private HashMap objectToMap(DynamicRealmObject object) {
        HashMap<String, Object> map = new HashMap<>();

        for (String fieldName : object.getFieldNames()) {
            if (object.isNull(fieldName)) {
                continue;
            }
            if (object.getFieldType(fieldName) == RealmFieldType.STRING_LIST) {
                Object value = object.getList(fieldName, String.class);
                map.put(fieldName, value);
                continue;
            }
            if (object.getFieldType(fieldName) == RealmFieldType.INTEGER_LIST) {
                Object value = object.getList(fieldName, Integer.class);
                map.put(fieldName, value);
                continue;
            }
            Object value = object.get(fieldName);
            map.put(fieldName, value);
        }
        return map;
    }

    private void mapToObject(DynamicRealmObject object, Map map) {
        for (String fieldName : object.getFieldNames()) {
            if (!map.containsKey(fieldName) || fieldName.equals("uuid")) {
                continue;
            }

            Object value = map.get(fieldName);
            if (value instanceof List) {
                RealmList newValue = new RealmList<>();
                newValue.addAll((List) value);
                value = newValue;
            }
            object.set(fieldName, value);
        }
    }

    private List convert(RealmResults<DynamicRealmObject> results) {
        ArrayList<Map> list = new ArrayList<>();

        for (DynamicRealmObject object : results) {
            HashMap map = objectToMap(object);
            list.add(map);
        }
        return Collections.unmodifiableList(list);
    }

    void reset() {
        subscriptions.clear();

        realm.beginTransaction();
        realm.deleteAll();
        realm.commitTransaction();
    }
}
